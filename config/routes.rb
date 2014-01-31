NanoApi::Engine.routes.draw do
  resources :searches, only: [:new, :create] do
    resources :clicks, only: :show do
      get :link, :deeplink, on: :member
    end
  end
  get '/searches/:id', to: 'searches#new', as: :search
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

  get '/searches_results' => 'searches#pick', as: :searches_pick
  get '/searches_mirror_results' => 'searches#get_mirror'
end
