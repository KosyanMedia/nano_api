module NanoApi
  class Client
    module Search

      MAPPING = {
        :'zh-CN' => :cn,
        :'en-GB' => :en_GB,
        :'en-IE' => :en_IE,
        :'en-AU' => :en_AU,
        :'en-NZ' => :en_AU,
        :'en-IN' => :en,
        :'en-SG' => :en,
        :'en-CA' => :en
      }

      def search params, options = {}
        path = NanoApi.config.search_path + (NanoApi.config.chain_prefix || '') + options[:chain]
        search_params = params.symbolize_keys.merge(
          marker: controller.try(:marker),
          user_ip: request.remote_ip,
          locale: MAPPING[I18n.locale] || I18n.locale,
          host: request.host
        )
        post_raw(path, search_params, options.reverse_merge!(host: :search_server))
      rescue RestClient::Exception => exception
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
