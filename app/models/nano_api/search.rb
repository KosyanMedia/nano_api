module NanoApi
  class Search
    include ActiveData::Model

    DEFAULT_DEPARTURE_OFFSET = 2.weeks
    DEFAULT_RETURN_OFFSET = 3.weeks

    attribute :range, type: Boolean, default: false
    attribute :trip_class, type: Integer, in: [0, 1], default: 0
    attribute :with_request, type: Boolean, default: false
    attribute :price

    embeds_many :segments, class: NanoApi::Segment
    embeds_one :passengers, class: NanoApi::Passengers

    accepts_nested_attributes_for :segments, :passengers

    delegate(:adults, :children, :infants, :adults=, :children=, :infants=, to: :passengers)

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
      segments.count == 1
    end

    def origin= value
      if value.is_a?(String)
        segments[0].origin.name = value
        segments[1].destination.name = value if segments[1]
      else
        segments[0].origin = value
        segments[1].destination = value if segments[1]
      end
    end

    def destination= value
      if value.is_a?(String)
        segments[0].destination.name = value
        segments[1].origin.name = value if segments[1]
      else
        segments[0].destination = value
        segments[1].origin = value if segments[1]
      end
    end

    [:iata=, :name=, :type=].each do |field|
      define_method "origin_#{field}" do |value|
        segments[0].origin.send(field, value)
        segments[1].destination.send(field, value) if segments[1]
      end

      define_method "destination_#{field}" do |value|
        segments[0].destination.send(field, value)
        segments[1].origin.send(field, value) if segments[1]
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
      segments[1].date = @return_date if segments[1]
    end

    def search options = {}
      NanoApi.client.search(search_params, options)
    end

    def params
      present_attributes.merge(
        segments: segments.map(&:params),
        passengers: passengers.present_attributes
      )
    end

    def search_params
      result = params.merge(trip_class: params[:trip_class] == 0 ? 'Y' : 'C')
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

    def non_default_params
      Hash[params.to_a - self.class.new.params.to_a]
    end

    def self.find id
      attributes = NanoApi.client.search_params(id)
      raise NotFound unless attributes
      new(attributes)
    end

    def initialize_with_defaults attributes = {}
      self.passengers = NanoApi::Passengers.new
      self.segments = [
        NanoApi::Segment.new(date: Date.current + DEFAULT_DEPARTURE_OFFSET),
        NanoApi::Segment.new(date: Date.current + DEFAULT_RETURN_OFFSET)
      ]
      initialize_without_defaults(attributes)
    end

    alias_method_chain :initialize, :defaults
  end
end
