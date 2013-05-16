require 'spec_helper'

describe NanoApi::Client do
  describe '.click' do
    let(:search){1122}
    let(:url){232}

    context 'standard api call' do
      before do
        stub_http_request(
          :post,
          NanoApi.config.search_server + '/searches/%d/order_urls/%d.json' % [search, url]
        ).to_return(
          body: '{"url": "http://test.com", "http_method": "post", "params": {"test_key": "test_value"}}'
        )
      end

      it 'should return parsed json' do
        subject.click(search, url).should == {
          url: 'http://test.com',
          http_method: 'post',
          params: {'test_key' => 'test_value'}
        }
      end
    end

    context 'handle api errors' do
      before do
        stub_http_request(
          :post,
          NanoApi.config.search_server + '/searches/%d/order_urls/%d.json' % [search, url]
        ).to_return(status: [404, 'Not Found'])
      end

      it 'should return parsed json' do
        subject.click(search, url).should be_nil
      end
    end
  end

  describe '.link' do
    let(:search){1122}
    let(:airline){'3425klnk5b13k5b23h5s'}

    before do
      stub_http_request(
        :get,
        NanoApi.config.search_server + "/airline_logo/#{airline}.json?locale=en&marker=&search_id=#{search}"
      ).to_return(body: '{"url": "http://test.com"}')
    end

    it 'should return parsed json' do
      subject.link(search, airline).should == {
        url: 'http://test.com'
      }
    end
  end

  describe '.deeplink' do
    let(:search){1122}
    let(:proposal){232}

    before do
      stub_http_request(
        :get,
        NanoApi.config.search_server + "/airline_deeplinks/#{proposal}.json?adults=1&locale=en&marker=&search_id=#{search}"
      ).to_return(body: '{"url": "http://test.com", "http_method": "post"}')
    end

    it 'should return parsed json' do
      subject.deeplink(search, proposal, :adults => 1).should == {
        url: 'http://test.com',
        http_method: 'post'
      }
    end
  end
end
