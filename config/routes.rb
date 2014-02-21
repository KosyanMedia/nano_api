NanoApi::Engine.routes.draw do
  resources :searches, only: [:new, :create, :show], path_names: {new: ''}, path: NanoApi.config.search_engine_path do
    collection do
      get :new, to: :new # For backwards compatibility
      post :get_search_params
    end

    resources :clicks, only: :none do
      member do
        get '', action: :show_face
        get :link
        get :deeplink, to: :deeplink_face
        get :show_load, to: :show, as: :show_load_search_click
        get :deeplink_load, to: :deeplink, as: :deeplink_load_search_click
      end
    end
  end

  post '/adaptors/chains/:chain' => 'searches#create'

  resources :clicks, only: :new
  resources :places, only: :index
  resources :airlines, only: :index
  resources :feedbacks, only: :create
  resources :subscribers, only: :create

  get '/week_minimal_prices' => 'minimal_prices#week', as: :week_minimal_prices
  get '/month_minimal_prices' => 'minimal_prices#month', as: :month_minimal_prices
  get '/nearest_cities_prices' => 'minimal_prices#nearest', as: :nearest_cities_prices
  match '/latest_prices' => 'minimal_prices#latest_prices', via: [:get, :post]
  get '/estimated_search_duration' => 'gate_meta#search_duration', as: :estimated_search_duration

  get '/searches_results:version' => 'searches#pick', constraints: {version: /.*/}, as: :searches_pick
  get '/searches_mirror_results' => 'searches#get_mirror'
end
