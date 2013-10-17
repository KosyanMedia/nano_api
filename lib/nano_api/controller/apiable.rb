module NanoApi
  module Controller
    module Apiable
      extend ActiveSupport::Concern

      included do
        include NanoApi::Controller::Locatable

        before_filter :initialize_api_instance
      end

    private

      def initialize_api_instance
        NanoApi.client = NanoApi::Client.new(self)
      end

      def search_instance attributes = {}
        NanoApi::Search.new(attributes).tap do |search|
          search.reverse_update_attributes(cookie_params)
          search.reverse_update_attributes(user_location_attributes)
        end
      end

      def cookie_params
        JSON.parse(cookies[:search_params].presence)['params_attributes'].slice(
          'origin', 'destination'
        ) rescue {}
      end

    end
  end
end
