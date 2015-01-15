module NanoApi
  class Client
    module Feedback

      def save_feedback params, options = {}
        path = NanoApi.config.feedback_path + (NanoApi.config.chain_prefix || '') + NanoApi.config.feedback_chain
        post_raw(path, params, options.reverse_merge!(host: :search_server))
      rescue RestClient::Exception => exception
        [exception.http_body, exception.http_code]
      rescue Errno::ECONNREFUSED
        ['Connection refused', 503]
      end

    end
  end
end
