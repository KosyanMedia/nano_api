NanoApi::Engine.routes.draw do
  resources :searches, only: :new, path_names: {new: ''}, path: NanoApi.config.search_engine_path do
    collection do
      get ':id', to: :show, constraints: { id: NanoApi::SearchIdParser::REGEX }
      match :get_search_params
      get :searches_mirror_results, to: :get_mirror
    end

    resources :clicks, only: :none do
      member do
        get '', action: :show_face
        get :link
        get :deeplink, to: :deeplink_face
        get :show_load, to: :show
        get :deeplink_load, to: :deeplink
      end
    end
  end

  get "#{NanoApi.config.search_engine_path}/new" => 'searches#new', as: nil # For backwards compatibility

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
end
