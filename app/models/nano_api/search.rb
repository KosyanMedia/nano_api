module NanoApi
  class Search
    include ActiveData::Model

    DEFAULT_DEPARTURE_OFFSET = 2.weeks
    DEFAULT_RETURN_OFFSET = 3.weeks

    attribute :range, type: Boolean, default: false
    attribute :trip_class, type: Integer, in: [0, 1], default: 0
    attribute :with_request, type: Boolean, default: false

    embeds_many :segments, class: NanoApi::Segment
    embeds_one :passengers, class: NanoApi::Passengers

    accepts_nested_attributes_for :segments, :passengers

    delegate(:adults, :children, :infants, :adults=, :children=, :infants=, to: :passengers)

    def one_way= value
      self.segments = [segments.first] if value.present? && value != '0'
    end

    def one_way
      segments.count == 1
    end

    def origin= value
      segments[0].origin = value
      segments[1].destination = value if segments[1]
    end

    def destination= value
      segments[0].destination = value
      segments[1].origin = value if segments[1]
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
      segments[0].date = value
    end

    def return_date
      segments[1].try(:date) || segments[0].date
    end

    def return_date= value
      segments[1].date = value if segments[1]
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
            place => segment[place][:iata],
            :"#{place}_name" => segment[place][:name] # Temporarily until there is the autocomplete validation.
          )
        end
      end
      result
    end

    def initial_params
      params.merge(
        return_date: return_date,
        one_way: one_way,
      )
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
