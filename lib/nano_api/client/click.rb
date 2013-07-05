module NanoApi
  class Client
    module Click
      YASEN_MIN_ORDER_URL_ID = 100_000

      def click search_id, order_url_id, params = {}
        host = order_url_id.to_i >= YASEN_MIN_ORDER_URL_ID
        post('searches/%s/order_urls/%d' % [search_id, order_url_id],
          params.merge(marker: marker), {host: host}).symbolize_keys
      rescue RestClient::ResourceNotFound
        nil
      end

      def link search_id, airline_id, params = {}
        get("airline_logo/#{airline_id}", params.merge(search_id: search_id, marker: marker), json: false).symbolize_keys
      end

      def deeplink search_id, proposal_id, params = {}
        get('airline_deeplinks/%d' % proposal_id, params.merge(search_id: search_id, marker: marker)).symbolize_keys
      end
    end
  end
end
