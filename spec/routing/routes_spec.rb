require 'spec_helper'

describe 'Routes' do
  routes { NanoApi::Engine.routes }

  context 'Minimal prices routes' do
    it 'should route latest prices with post method' do
      post('/latest_prices').should route_to('nano_api/minimal_prices#latest_prices')
    end

    it 'should route latest prices' do
      get('/latest_prices').should route_to('nano_api/minimal_prices#latest_prices')
    end

    it 'should route week minimal prices'
    it 'should route month minimal prices'
  end

  context 'Searches routes' do
    it 'should route new search'
    it 'should route search creation'
  end

  context 'Clicks routes' do
    it 'should route click creation'
  end

  context 'Auto complete routes' do
    it 'should route auto complete'
  end

  context 'GateMeta routes' do
    it 'should route estimated search duration'
  end

  context 'Airlines routes' do
    it 'should route airlines for direction'
  end
end
