require 'spec_helper'

describe NanoApi::Client do
  describe '#perform' do
    subject(:client) { NanoApi::Client.new(double(:controller, request: request, session: {})) }
    let(:request) do
      double(:request, remote_ip: '127.0.0.1', env: {'HTTP_ACCEPT_LANGUAGE' => 'lang'}, referer: '', host: '')
    end

    before do
      stub_request(:get, url).
        with(headers: {'Accept-Language' => 'lang'}).to_return(status: 200, body: 'answer')
    end

    context do
      let(:url) { "http://test.te/path.json?foo=bar&locale=en&user_ip=127.0.0.1" }
      specify { client.send(:perform, :get, 'path', { foo: 'bar' }).should == 'answer' }
    end

    context do
      let(:url) { "http://another.host/path.json?foo=bar&locale=en&user_ip=127.0.0.1" }
      specify { client.send(:perform, :get, 'path', { foo: 'bar' }, { host: 'another.host' }).should == 'answer' }
    end

    context do
      let(:url) { "http://test.te/path.json?foo=bar&locale=de&user_ip=127.0.0.3" }

      specify do
        client.send(:perform, :get, 'path', {foo: 'bar', locale: 'de', user_ip: '127.0.0.3'}).should == 'answer'
      end
    end
  end

  describe '.affiliate_marker?' do
    let(:affiliate_markers){['12346', '12346.lo']}
    let(:non_affiliate_markers){['yandex.org', '10.0.2.4', '', nil]}

    it 'should return true if marker of affiliate' do
      affiliate_markers.each do |marker|
        NanoApi::Client.affiliate_marker?(marker).should be_true
      end
    end

    specify 'should return false if marker is not of affiliate' do
      non_affiliate_markers.each do |marker|
        NanoApi::Client.affiliate_marker?(marker).should be_false
      end
    end
  end

  describe '.site' do
    let(:config){OpenStruct.new({
      nano_server: :nano_server_url,
      search_server: :search_server_url,
      travelpayouts_server: :travelpayouts_server_url
    })}

    before do
      NanoApi.stub(:config).and_return(config)
    end

    specify{NanoApi::Client.site.url.should == :nano_server_url}
    specify{NanoApi::Client.site(:search_server).url.should == :search_server_url}
    specify{NanoApi::Client.site(:travelpayouts_server).url.should == :travelpayouts_server_url}
    specify{NanoApi::Client.site(:not_exists).url.should == :nano_server_url}

    context 'without nano_server in config' do
      let(:config){OpenStruct.new({
        search_server: :search_server_url,
      })}

      specify{NanoApi::Client.site.url.should == :search_server_url}
    end
  end

  describe '.signature' do
    specify {NanoApi::Client.signature(12345).should == Digest::MD5.hexdigest("#{NanoApi.config.api_token}:12345")}
    specify {NanoApi::Client.signature(12345, 'hello', 'world').should == Digest::MD5.hexdigest("#{NanoApi.config.api_token}:12345:hello:world")}
    specify {NanoApi::Client.signature(12345, ['email']).should == Digest::MD5.hexdigest("#{NanoApi.config.api_token}:12345:email")}
  end
end
