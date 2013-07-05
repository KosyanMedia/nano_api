module NanoApi
  class Client
    module Affiliate
      def affiliate
        affiliate_marker = self.class.extract_marker(marker)
        return unless affiliate_marker

        result = get('affiliates/%d' % affiliate_marker, signature: affilate_signature(affiliate_marker))
        return unless result.has_key?('affiliate')

        result['affiliate'].merge(result['affiliate'].delete('info'))
      rescue RestClient::ResourceNotFound,
        RestClient::BadRequest,
        RestClient::Forbidden,
        RestClient::ServiceUnavailable,
        RestClient::MethodNotAllowed,
        RestClient::InternalServerError,
        JSON::ParserError
          nil
      end

      def affilate_signature affiliate_marker
        self.class.signature affiliate_marker, []
      end
    end
  end
end
