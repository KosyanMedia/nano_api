module NanoApi
  class ApplicationController < ::ApplicationController
    skip_before_filter :verify_authenticity_token
    nano_extend

  protected

    def forward_json json, status = :ok
      response.content_type = Mime::JSON
      if defined?(Rollbar) && status != :ok
        Rollbar.report_exception NanoApi::Client::RequestError.new(json), status: status
      end
      render text: json, status: status
    end
  end
end
