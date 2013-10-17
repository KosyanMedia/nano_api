module NanoApi
  class Client
    module Airlines
      def airlines_for_direction origin, destination
        get_raw('airlines_for_direction',
          origin_iata: origin, destination_iata: destination
        )
      end
    end
  end
end
