require 'spec_helper'

describe NanoApi::ClicksController do
  render_views

  describe 'GET new' do
    context do
      it 'should render from with params, received from api' do
        NanoApi::Client.any_instance.should_receive(:click).with('111', '123', hash_including(unique: '1')).and_return(
          url: 'http://test.com',
          method: 'post',
          params: {test: 'test_value'}
        )
        get :show, use_route: :nano_api, search_id: 111, id: 123

        response.should be_success
        response.body
        response.should render_template(:show)
        response.body.should have_selector('form[method=post][action="http://test.com"]')
        response.body.should have_selector('input[type=hidden][name=test][value=test_value]')
      end
    end

    context do
      before do
        NanoApi::Client.any_instance.stub(:click)
        get :show, use_route: :nano_api, search_id: 222, id: 234
      end

      it 'should be non-uniq click after first' do
        NanoApi::Client.any_instance.should_receive(:click).with('111', '123', hash_not_including(unique: '1'))
        get :show, use_route: :nano_api, search_id: 111, id: 123
      end
    end

  end

  describe 'GET show' do
    it 'should make api call with marker' do
      NanoApi::Client.any_instance.should_receive(:post).
        with('searches/111/order_urls/123', hash_including(marker: 'direct'), {search_host: false}).
        and_return(
          url: 'http://test.com',
          method: 'post',
          params: {test: 'test_value'}
        )
      get :show, use_route: :nano_api, search_id: 111, id: 123
    end
  end

  describe 'GET link' do
    it 'should make api call with marker' do
      NanoApi::Client.any_instance.should_receive(:get).
        with('airline_logo/123', hash_including(marker: 'direct'), {json: false}).and_return(
          url: 'http://test.com',
          method: 'get',
          params: {test: 'test_value'}
        )
      get :link, use_route: :nano_api, search_id: 111, id: 123
    end
  end

  describe 'GET deeplink' do
    it 'should make api call with marker' do
      NanoApi::Client.any_instance.should_receive(:get).
        with('airline_deeplinks/123', hash_including(marker: 'direct')).and_return(
          url: 'http://test.com',
          method: 'get',
          params: {test: 'test_value'}
        )
      get :deeplink, use_route: :nano_api, search_id: 111, id: 123
    end
  end
end
