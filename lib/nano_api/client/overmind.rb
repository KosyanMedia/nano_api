module NanoApi
  class Client
    module Overmind
      def place iata, locale = I18n.locale
        return "[]" if iata.blank?
        resource = RestClient::Resource.new(NanoApi.config.data_server)
        resource["api/places?code=#{iata}&locale=#{locale}"].get
      rescue
        "[]"
      end
    end
  end
end
