module NanoApi
  class MinimalPricesController < NanoApi::ApplicationController
    def week
      forward_json NanoApi.client.week_minimal_prices(params[:search_id], params[:direct_date], params[:return_date])
    end

    def month
      forward_json NanoApi.client.month_minimal_prices(params[:search_id], params[:month])
    end

    def nearest
      forward_json NanoApi.client.nearest_cities_prices(params[:search_id])
    end

    def latest_prices
      result = NanoApi.client.latest_prices(params)
      @prices = result[:prices]
      @last_page = result[:last_page]
      @exact_direction = result[:exact_direction]

      @route_hash = {
        origin: result[:origin],
        destination: result[:destination],
        price_counter: result[:prices].count
      }

      respond_to do |format|
        format.js
        format.html
      end
    end
  end
end
