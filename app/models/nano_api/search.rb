module NanoApi
  class Search
    include ActiveData::Model

    DEFAULT_DEPARTURE_OFFSET = 2.weeks
    DEFAULT_RETURN_OFFSET = 3.weeks

    TRIP_CLASS_MAPPING = {
      '0' => 'Y',
      '1' => 'C'
    }

    TRIP_CLASSES = %w(Y C W F)

    LOCALES_TO_HOSTS = defined?(Settings) && Settings.hosts.respond_to?(:to_hash) ?
      Settings.hosts.to_hash.stringify_keys.invert.symbolize_keys : {}

    STORE_PARAMS = [:trip_class, :open_jaw, :segments, :passengers]
    DISPLAY_PARAMS = STORE_PARAMS + [:with_request, :price]

    attribute :trip_class, type: String, in: TRIP_CLASSES, default: 'Y'
    attribute :with_request, type: Boolean, default: false
    attribute :open_jaw, type: Boolean, default: false
    attribute :internal, type: Boolean, default: false
    attribute :bot, type: Boolean, default: false
    attribute :price
    attribute :locale
    attribute :test_name
    attribute :test_rule
    attribute :platform
    attribute :_ga
    attribute :auid
    attribute :host
    attribute :user_ip
    attribute :marker

    embeds_many :segments, class: NanoApi::Segment
    embeds_one :passengers, class: NanoApi::Passengers

    accepts_nested_attributes_for :segments, :passengers

    delegate(:adults, :children, :infants, :adults=, :children=, :infants=, to: :passengers)

    def host
      result = super || LOCALES_TO_HOSTS[locale]
      if result
        result = "internal.#{result}" if internal?
        result = "bot.#{result}" if bot?
      end
      result
    end

    def locale
      super.try(:to_sym) || I18n.locale
    end

    def trip_class= value
      super(TRIP_CLASS_MAPPING[value.to_s] || value)
    end

    def one_way= value
      if value.present? && value != '0'
        self.segments = [segments.first]
      elsif segments.count == 1
        segment_params = segments.first.params
        return_segment_params = segment_params.merge(
          origin: segment_params[:destination],
          destination: segment_params[:origin]
        )
        return_segment_params[:date] = @return_date if @return_date
        self.segments << NanoApi::Segment.new(return_segment_params)
      end
    end

    def one_way
      segments.count == 1 && !open_jaw
    end

    def round_trip
      segments.count == 2 && !open_jaw
    end

    # Sets open_jaw to true when it's impossible to represent the search params in the simple form, not when the search
    # will be processed as open_jaw by Yasen.
    def set_open_jaw_by_segments
      self.open_jaw = get_open_jaw_by_segments
    end

    def get_open_jaw_by_segments
      segments.count > 2 || segments.count == 2 && (segments[0].origin != segments[1].destination ||
        segments[0].destination != segments[1].origin)
    end

    def origin= value
      if value.is_a?(String)
        segments[0].origin.name = value
        segments[1].destination.name = value if round_trip
      else
        segments[0].origin = value
        segments[1].destination = value if round_trip
      end
    end

    def destination= value
      if value.is_a?(String)
        segments[0].destination.name = value
        segments[1].origin.name = value if round_trip
      else
        segments[0].destination = value
        segments[1].origin = value if round_trip
      end
    end

    [:iata=, :name=, :type=].each do |field|
      define_method "origin_#{field}" do |value|
        segments[0].origin.send(field, value)
        segments[1].destination.send(field, value) if round_trip
      end

      define_method "destination_#{field}" do |value|
        segments[0].destination.send(field, value)
        segments[1].origin.send(field, value) if round_trip
      end
    end

    def depart_date
      segments[0].date
    end

    def depart_date= value
      segments[0].date = value.is_a?(String) ? value.gsub(/\+/, ' ') : value
    end

    def return_date
      segments[1].try(:date) || segments[0].date
    end

    def return_date= value
      @return_date = value.is_a?(String) ? value.gsub(/\+/, ' ') : value
      segments[1].date = @return_date if round_trip
    end

    def fix_dates_order
      ordered_dates = segments.length > 1 ? segments.each_cons(2).all? { |l_s, r_s| (l_s.date <=> r_s.date) <= 0 } : true
      unless ordered_dates
        segments.each { |segment| segment.date = nil }
        :unordered_dates
      end
    end

    def fix_dates_value
      min_date = Time.now.getlocal(NanoApi::SearchId::MIN_TIMEZONE).to_date
      max_date = min_date + 1.year - 1.day
      valid_dates = segments.all? { |segment|
        segment.date.try(:between?, min_date, max_date)
      }
      unless valid_dates
        segments.each { |segment| segment.date = nil }
        :bad_dates
      end
    end

    def errors
      [fix_dates_value, fix_dates_order].compact
    end

    def search options = {}
      options[:chain] ||= if get_open_jaw_by_segments
        options[:openjaw_chain] || Settings.nano_api.openjaw_chain
      else
        options[:simple_chain] || Settings.nano_api.regular_chain
      end
      NanoApi.client.search(search_params, options)
    end

    def params
      present_attributes.merge(
        segments: segments.map(&:params),
        passengers: passengers.present_attributes
      ).with_indifferent_access
    end

    def display_params
      params.slice(*DISPLAY_PARAMS)
    end

    def store_params
      params.slice(*STORE_PARAMS)
    end

    def search_params
      result = params
      result[:locale] = result[:locale].to_s.sub('-', '_')
      result.delete(:open_jaw)
      result[:segments].each do |segment|
        [:origin, :destination].each do |place|
          segment.merge!(
            place => segment[place][:iata] || '',
            # Temporarily until there is the autocomplete validation.
            :"#{place}_name" => segment[place][:city] || segment[place][:name]
          )
        end
      end
      result
    end

    def non_default_display_params
      Hash[display_params.to_a - self.class.new.display_params.to_a]
    end

    def initialize_with_defaults attributes = {}
      self.passengers = NanoApi::Passengers.new
      self.segments = [
        NanoApi::Segment.new(date: Date.current + DEFAULT_DEPARTURE_OFFSET),
        NanoApi::Segment.new(date: Date.current + DEFAULT_RETURN_OFFSET)
      ]
      initialize_without_defaults(attributes)
    end

    class << self
      def find id
        attributes = NanoApi.client.search_params(id)
        raise NotFound unless attributes
        new(attributes)
      end

      def open_jaw_new attributes = {}
        search = new(segments: 2.times.map { NanoApi::Segment.new }, open_jaw: true)
        search.update_attributes(attributes)
        search
      end

      def default_display_params
        new.display_params
      end
    end

    alias_method_chain :initialize, :defaults
  end
end
