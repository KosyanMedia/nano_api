module NanoApi
  class SearchesController < NanoApi::ApplicationController
    include NanoApi::Extensions::Markerable
    include NanoApi::Extensions::UserLocation

    before_filter :handle_marker, :only => :new

    def new
      @search = Search.new(search_params)
    end

    def show
      @search = Search.find(params[:id])
      render :new
    end

    def create
      @search = Search.new(params[:search].is_a?(Hash) ? params[:search] : params)
      cookies[:ls] = @search.attributes_for_cookies.to_json

      search_result = @search.search(request.host)

      if search_result.present?
        forward_json(*search_result)
      else
        render json: {}, status: :internal_server_error
      end
    end

  private

    def search_params
      cookie_defaults = JSON.parse(cookies[:ls].presence) rescue {}
      search_params = params[:search].is_a?(Hash) ? params[:search] : params
      user_location_attributes.merge(cookie_defaults).merge(search_params)
    end

  end
end
