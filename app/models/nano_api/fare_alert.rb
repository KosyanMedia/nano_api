module NanoApi
  class FareAlert
    include ActiveData::Model

    attribute :origin_iata
    attribute :origin_name
    attribute :destination_iata
    attribute :destination_name
    attribute :depart_date, type: Date
    attribute :return_date, type: Date
  end
end