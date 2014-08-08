class NanoApi::Backends::SearchesController < NanoApi::ApplicationController
  helper_method :show_hotels?, :show_hotels_type

  def pick
    url = "#{NanoApi.config.search_server}/searches_results#{params[:version]}?uuid=#{params[:uuid]}"
    answer = RestClient.get(url)
    render json: (JSON.parse(answer) rescue answer)
  end

  def get_mirror
    render json: JSON.parse(RestClient.get("#{NanoApi.config.search_server}/searches_mirror_results?eid=#{params[:eid]}"))
  end

  def new
    @search = search_instance search_params
  end

  def show
    search = get_search_by_id
    if search.open_jaw
      @open_jaw_search = search
    else
      @search = search
    end
    @search_params_key = params[:id]
    render :new
  end

  def get_search_params
    result = if params[:encoded_search]
      params[:id] = params.delete(:encoded_search)
      get_search_by_id
    else
      search_instance search_params
    end
    render json: result.non_default_params
  end

  def slice_split_params
    split_description = request.cookies.slice *%w(test_name test_rule)
    split_description.values.any?(&:blank?) || Time.now.to_i > request.cookies['test_stop'].to_i ? nil : split_description
  end

  def create
    @search = NanoApi::Search.new(search_params.merge(with_request: false).merge(slice_split_params || {}))
    cookies.permanent[@search.open_jaw ? :open_jaw_search_params : :search_params] = {
      value: @search.params.to_json,
      domain: default_nano_domain
    }

    search_result = @search.search(search_options)

    if search_result.present?
      if search_result.is_a?(String)
        if rates = JSON.parse(search_result)['currency_rates']
          Rails.cache.write(NanoApi.config.rates_cache, rates.to_json)
        end
        search_id = get_search_id(search_result)
        auid = request.cookies['auid'].to_s.gsub(/\s/, '+')
        track_search(search_id, auid)
        response.headers['X-Search-Id'] = search_id
      end
      forward_json(*search_result)
    else
      render json: {}, status: :internal_server_error
    end
  end

private

  def search_engine_scope?
    true
  end

  def get_search_by_id
    if search = NanoApi::SearchId.parse(params[:id])
      postprocess_search(search)
      search.set_open_jaw_by_segments # Must be done after the postprocessing.
      search
    else
      Rollbar.report_exception(ArgumentError.new('Failed to parse search id'), rollbar_request_data, rollbar_person_data)
      search_instance(search_params)
    end
  end

  def search_options
    {
      know_english: cookies[:know_english] == 'true',
      chain: params[:chain]
    }
  end

  def search_params
    params[:search].is_a?(Hash) ? params[:search].reverse_merge(with_request: params[:with_request]) : params
  end

  def show_hotels?
    return false if hide_hotels_by_params?

    affiliate_attribute :show_hotels, true
  end

  def show_hotels_type
    affiliate_attribute :show_hotels_type, :without_hotels
  end

  def hide_hotels_by_params?
    'false' == params[:show_hotels]
  end

  def get_search_id search_result
    match = search_result.match /"search_id":\s*"([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})"/
    # Backward compatibility with nano search
    match = search_result.match /"search_id":(\d+)/ unless match
    id = match ? match.captures.first : ''
  end

  def track_search search_id, auid
    return unless NanoApi.config.pulse_server.present?
    url = NanoApi.config.pulse_server + "/?event=search&search_id=#{search_id}&auid=#{auid}&marker=#{URI.encode(marker)}"
    RestClient::Request.execute(method: :get, url: url, timeout: 3.seconds, open_timeout: 3.seconds)
  rescue => e # Gotta catch 'em all
    Rollbar.report_exception(e) if defined?(Rollbar)
  end
end
