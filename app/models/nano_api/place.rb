module NanoApi
  class Place
    include ActiveData::Model

    attribute :iata
    attribute :name
    attribute :type
    attribute :city

    def params
      result = present_attributes
      result.delete(:city) if result[:city] == result[:name]
      result
    end
  end
end
