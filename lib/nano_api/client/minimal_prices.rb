module NanoApi::Client::MinimalPrices
  def week_minimal_prices search_id, direct_date = nil, return_date = nil
    get_raw('minimal_prices',
      search_id: search_id, direct_date: direct_date, return_date: return_date
    )
  end

  def month_minimal_prices search_id, month = nil
    get_raw('month_minimal_prices', search_id: search_id, month: month)
  end

  def nearest_cities_prices search_id
    get_raw('nearest_cities_prices', search_id: search_id)
  end

  LATEST_PRICES_PER_PAGE = 30

  def latest_prices params
    latest_prices_params = params.slice(
      :origin, :destination, :origin_iata, :destination_iata, :period,
      :trip_duration, :sorting, :one_way, :page, :currency, :show_to_affiliates, :period, :per_page
    ).reverse_merge(show_to_affiliates: affiliate?, per_page: LATEST_PRICES_PER_PAGE)

    get('latest_prices', latest_prices_params).try(:symbolize_keys)
  end
end
