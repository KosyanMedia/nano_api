require 'spec_helper'

describe NanoApi::Client do
  describe '#perform' do
    subject(:client) { NanoApi::Client.new(double(:controller, request: request)) }
    let(:request){double(:request, remote_ip: '127.0.0.1', env: {'HTTP_ACCEPT_LANGUAGE' => 'lang'})}

    context do
      before { stub_request(:get, "http://test.te/path.json?foo=bar&locale=en&user_ip=127.0.0.1").
        with(headers: {'Accept-Language' => 'lang'}).
        to_return(:status => 200, :body => 'answer') }
      specify { client.send(:perform, :get, 'path', { foo: 'bar' }).should == 'answer' }
    end

    context do
      before { stub_request(:get, "http://another.host/path.json?foo=bar&locale=en&user_ip=127.0.0.1").
        with(headers: {'Accept-Language' => 'lang'}).
        to_return(:status => 200, :body => 'answer') }
      specify { client.send(:perform, :get, 'path', { foo: 'bar' }, { host: 'another.host' }).should == 'answer' }
    end

    context do
      before do
        stub_request(:get, "http://test.te/path.json?foo=bar&locale=de&user_ip=127.0.0.3").
          with(headers: {'Accept-Language' => 'lang'}).
          to_return(:status => 200, :body => 'answer')
      end

      specify do
        client.send(:perform, :get, 'path',
          {foo: 'bar', locale: 'de', user_ip: '127.0.0.3'}
        ).should == 'answer'
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
      nano_server: :nano_server,
      search_server: :search_server,
      travelpayouts_server: :travelpayouts_server
    })}

    before do
      NanoApi.stub(:config).and_return(config)
    end

    specify{NanoApi::Client.site.url.should == :nano_server}
    specify{NanoApi::Client.site(true).url.should == :search_server}
    specify{NanoApi::Client.site(false, :travelpayouts_server).url.should == :travelpayouts_server}
    specify{NanoApi::Client.site(false, :not_exists).url.should == :nano_server}

    context 'without nano_server in config' do
      let(:config){OpenStruct.new({
        search_server: :search_server,
      })}

      specify{NanoApi::Client.site.url.should == :search_server}
    end
  end

  describe '.signature' do
    specify {NanoApi::Client.signature(12345).should == Digest::MD5.hexdigest("#{NanoApi.config.api_token}:12345")}
    specify {NanoApi::Client.signature(12345, 'hello', 'world').should == Digest::MD5.hexdigest("#{NanoApi.config.api_token}:12345:hello:world")}
    specify {NanoApi::Client.signature(12345, ['email']).should == Digest::MD5.hexdigest("#{NanoApi.config.api_token}:12345:email")}
  end
end
