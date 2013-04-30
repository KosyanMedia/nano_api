module NanoApi
  class Client
    module Places

      def auto_complete_place term, locale = I18n.locale
        locale = MAPPING[locale] || locale
        get_raw('places_%s' % locale, term: term)
      rescue RestClient::BadRequest
        nil
      end

      def geoip ip, locale = I18n.locale
        locale = MAPPING[locale] || locale
        get('places/ip_to_places_%s' % locale, ip: ip).first.try(:symbolize_keys)
      end
    end
  end
end
