require 'spec_helper'

describe 'Routes' do
  routes { NanoApi::Engine.routes }

  context 'Minimal prices routes' do
    it 'routes to latest prices with post method' do
      post('/latest_prices').should route_to('nano_api/minimal_prices#latest_prices')
    end

    it 'routes to latest prices' do
      get('/latest_prices').should route_to('nano_api/minimal_prices#latest_prices')
    end

    specify do
      get('/searches/AHKT3010ABKK13111').should route_to('nano_api/searches#new', id: 'AHKT3010ABKK13111')
    end
  end
end
