module NanoApi
  class ApplicationController < ::ApplicationController
    skip_before_filter :verify_authenticity_token
    nano_extend

  protected

    def forward_json json, status = :ok
      response.content_type = Mime::JSON
      render text: json, status: status
    end
  end
end
