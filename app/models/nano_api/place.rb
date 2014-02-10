module NanoApi
  class Place
    include ActiveData::Model

    attribute :iata
    attribute :name
    attribute :type
    attribute :city
  end
end
