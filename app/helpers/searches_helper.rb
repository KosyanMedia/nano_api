module SearchesHelper
  def trip_classes_map
    {
      t('nano_api.searches.helpers.trip_classes.economy_upcase') => 0,
      t('nano_api.searches.helpers.trip_classes.business_upcase') => 1
    }
  end

  def nano_api_urls
    {
      search_path: nano_api.searches_path(format: :json),
      search_method: :post,
      click_path: nano_api.new_click_path(format: :json),
      autocomplete_path: nano_api.places_path(format: :json),
      week_minimal_prices: nano_api.week_minimal_prices_path(format: :json),
      month_minimal_prices: nano_api.month_minimal_prices_path(format: :json)
    }
  end
end
