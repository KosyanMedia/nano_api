NanoApi::Engine.routes.draw do
  resources :searches, only: [:show, :new, :create] do
    resources :clicks, only: :show do
      member do
        get :link, :deeplink
      end
    end
  end
  resources :clicks, only: :new
  resources :places, only: :index
  resources :airlines, only: :index
  resources :ui_events, only: [] do
    collection do
      post :mass_create
    end
  end
  resources :feedbacks, only: :create
  resources :subscribers, only: :create
  get '/week_minimal_prices' => 'minimal_prices#week', as: :week_minimal_prices
  get '/month_minimal_prices' => 'minimal_prices#month', as: :month_minimal_prices
  get '/nearest_cities_prices' => 'minimal_prices#nearest', as: :nearest_cities_prices
  get '/latest_prices' => 'minimal_prices#latest_prices'
  post '/latest_prices' => 'minimal_prices#latest_prices'
  get '/estimated_search_duration' => 'gate_meta#search_duration', as: :estimated_search_duration
end
