module NanoApi
  class Client
    module Search
      SEARCH_PARAMS_KEYS = %w[
        origin_iata origin_name destination_iata destination_name
        depart_date return_date
        adults children infants
        trip_class range
      ].map(&:to_sym)

      def search params, options = {}
        params.symbolize_keys!
        marker = params[:marker].presence || api_client_marker(controller.try(:marker))
        allowed_params = params.slice(*SEARCH_PARAMS_KEYS).inject({}) do |result, (key, value)|
          result[key] = value if value.present?
          result
        end

        post_raw('searches', {
          signature: api_client_signature(marker, allowed_params),
          enable_api_auth: true,
          locale: extract_locale(params),
          search: {
            host: params[:host].presence || request.try(:host),
            user_ip: params[:user_ip].presence || request.try(:remote_ip),
            marker: marker,
            params_attributes: allowed_params
          }
        }, options)
      rescue RestClient::ResourceNotFound,
        RestClient::BadRequest,
        RestClient::Forbidden,
        RestClient::ServiceUnavailable,
        RestClient::MethodNotAllowed => exception
          [exception.http_body, exception.http_code]
      rescue RestClient::InternalServerError
        nil
      end

      def search_params id
        result = get('/searches/%d' % id)
        result.merge!('one_way' => true) if result['return_date'].blank?
        result
      end

      def search_duration
        get('estimated_search_duration')['estimated_search_duration'].to_i
      end

    private
      def extract_locale params
        locale = params[:locale].presence || I18n.locale
        NanoApi::Client::MAPPING[locale] || locale
      end

      def api_client_signature marker, params
        Digest::MD5.hexdigest(
          [NanoApi.config.api_token, marker, *params.values_at(*params.keys.sort)].join(?:)
        )
      end

      def api_client_marker additional_marker
        result = [additional_marker]
        result.unshift(NanoApi.config.marker) if NanoApi.config.marker.present?
        result.compact.join(?.)
      end
    end
  end
end
