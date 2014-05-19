module NanoApi
  class Client
    module Search

      def search params, options = {}
        path = NanoApi.config.search_path + (NanoApi.config.chain_prefix || '') + options[:chain]
        search_params = params.symbolize_keys.merge(
          marker: controller.try(:marker),
          user_ip: request.try(:remote_ip),
        )
        search_params[:host] = request.host if request.try(:host).present?
        post_raw(path, search_params, options.reverse_merge!(host: :search_server))
      rescue RestClient::Exception, Errno::ECONNREFUSED => exception
        [exception.http_body, exception.http_code]
      end

      def search_params id
        result = get('/searches/%s' % id)
        result.merge!('one_way' => true) if result['return_date'].blank?
        result
      end

      def search_duration
        get('estimated_search_duration')['estimated_search_duration'].to_i
      end

    private
      def api_client_marker additional_marker
        result = [additional_marker]
        result.unshift(NanoApi.config.marker) if NanoApi.config.marker.present?
        result.compact.join(?.)
      end
    end
  end
end
