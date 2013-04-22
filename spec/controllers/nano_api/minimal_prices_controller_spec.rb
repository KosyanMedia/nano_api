require 'spec_helper'

describe NanoApi::MinimalPricesController do
  describe 'GET week' do
    it 'should forward json, received from api minimal_prices action' do
      NanoApi::Client.any_instance.should_receive(:week_minimal_prices).with('1233', '2011-11-12', nil).and_return('{test: 1}')
      get :week, use_route: :nano_api, search_id: 1233, direct_date: Date.new(2011, 11, 12)
      response.content_type.should == Mime::JSON
      response.body.should == '{test: 1}'
    end
  end

  describe 'GET month' do
    it 'should forward json, received from api minimal_prices action' do
      NanoApi::Client.any_instance.should_receive(:month_minimal_prices).with('1233', '2011-11-01').and_return('{test: 2}')
      get :month, use_route: :nano_api, search_id: 1233, month: Date.new(2011, 11, 1)
      response.content_type.should == Mime::JSON
      response.body.should == '{test: 2}'
    end
  end

  describe 'GET latest_prices' do
    it 'should pass params into nano_api client call' do
      params = {origin: 'test'}

      NanoApi::Client.any_instance.should_receive(:latest_prices).
        with(hash_including(params)).and_return(prices: [1, 2, 3])

      get :latest_prices, params.merge(use_route: :nano_api, format: :js)
    end

    it 'should be successful with js format' do
      NanoApi::Client.any_instance.stub(:latest_prices).and_return(prices: [1, 2, 3])

      get :latest_prices, use_route: :nano_api, format: :js
      assigns[:prices].should == [1, 2, 3]
      response.should be_success
      response.should render_template(:latest_prices)
    end

    it 'should be successful with html format' do
      NanoApi::Client.any_instance.stub(:latest_prices).and_return(prices: [1, 2, 3])

      get :latest_prices, use_route: :nano_api, format: :html
      assigns[:route_hash].should be
      response.should be_success
      response.should render_template(:latest_prices)
    end
  end
end
