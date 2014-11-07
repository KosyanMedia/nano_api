module NanoApi
  class Passengers
    include ActiveData::Model

    attribute :adults, type: Integer, in: (1..9), default: 1
    attribute :children, type: Integer, in: (0..8), default: 0
    attribute :infants, type: Integer, in: (0..5), default: 0
  end
end