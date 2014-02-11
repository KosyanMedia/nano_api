module NanoApi
  module Backends
    class ApplicationController < ::ApplicationController
      skip_before_filter :verify_authenticity_token

    protected

      def forward_json json, status = :ok
        response.content_type = Mime::JSON
        if defined?(Rollbar) && status != :ok
          Rollbar.report_exception NanoApi::Client::RequestError.new(json), status: status
        end
        if json.respond_to?(:headers) && json.headers[:x_yasen_eid]
          response.headers['X-Yasen-EID'] = json.headers[:x_yasen_eid]
        end
        render text: json, status: status
      end
    end
  end
end