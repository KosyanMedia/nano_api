module NanoApi
  class Client
    module Search

      def search params, options = {}
        path = NanoApi.config.search_path + (NanoApi.config.chain_prefix || '') + options[:chain]
        user_ip = request.try(:remote_ip)
        search_params = params.symbolize_keys.merge(
          marker: controller.try(:marker),
          user_ip: user_ip,
        )
        search_params[:host] = request.host if request.try(:host).present?

        if user_ip &&
          (country_host_override = CmsEngine::DomainConfig.current.country_host_override.with_indifferent_access) &&
          (country_code = CmsEngine.geoip.try(:country, user_ip).try(:country_code2)) &&
          (host_replacement = country_host_override[country_code])
          search_params[:host] = host_replacement
        end
        post_raw(path, search_params, options.reverse_merge!(host: :search_server))
      rescue RestClient::Exception => exception
        [exception.http_body, exception.http_code]
      rescue Errno::ECONNREFUSED
        ['Connection refused', 503]
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
