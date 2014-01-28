module NanoApi
  class Segment
    include ActiveData::Model

    attribute :date, type: Date

    embeds_one :origin, class: NanoApi::Place
    embeds_one :destination, class: NanoApi::Place

    accepts_nested_attributes_for(:origin, :destination)

    def params
      attributes.merge(origin: origin.attributes, destination: destination.attributes)
    end

    def initialize_with_defaults attributes={}
      self.origin = NanoApi::Place.new
      self.destination = NanoApi::Place.new
      initialize_without_defaults(attributes)
    end

    alias_method_chain :initialize, :defaults
  end
end
