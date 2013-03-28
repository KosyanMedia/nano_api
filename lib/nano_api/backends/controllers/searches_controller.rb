class NanoApi::Backends::SearchesController < NanoApi::ApplicationController
  helper_method :show_hotels?

  def new
    @search = search_instance search_params
  end

  def show
    @search = NanoApi::Search.find(params[:id])
    render :new
  end

  def create
    @search = NanoApi::Search.new(search_params)
    cookies[:search_params] = {
      :value => @search.search_params.to_json,
      :domain => (request.domain unless request.local?)
    }

    search_result = @search.search
    increase_referer_search_count!

    if search_result.present?
      forward_json(*search_result)
    else
      render json: {}, status: :internal_server_error
    end
  end

private

  def search_params
    params[:search].is_a?(Hash) ? params[:search] : params
  end

  def show_hotels?
    return false if hide_hotels_by_params?

    affiliate_attribute :show_hotels, true
  end

  def hide_hotels_by_params?
    'false' == params[:show_hotels]
  end
end
