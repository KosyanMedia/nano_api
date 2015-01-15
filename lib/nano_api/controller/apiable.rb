module NanoApi
  module Controller
    module Apiable
      extend ActiveSupport::Concern

    private

      def initialize_api_instance
        NanoApi.client = NanoApi::Client.new(self)
      end

      def postprocess_search(search)
        places = search.segments.flat_map { |segment| segment.params.values_at(:origin, :destination) }
        if places.any?(&:present?)
          request_search_data(places).in_groups_of(2).zip(search.segments) do |processed_places, segment|
            segment.update_attributes(origin: processed_places[0], destination: processed_places[1])
          end
        end
        search
      end

      def cookie_params
        JSON.parse(cookies[:search_params].presence) rescue {}
      end

      def open_jaw_cookie_params
        JSON.parse(cookies[:open_jaw_search_params].presence) rescue {}
      end
    end
  end
end
