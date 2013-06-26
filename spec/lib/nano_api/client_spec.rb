require 'spec_helper'

describe NanoApi::Client do
  describe '#perform' do
    subject(:client) { NanoApi::Client.new }

    context do
      before { stub_request(:get, "http://test.te/path.json?foo=bar&locale=en").
        to_return(:status => 200, :body => 'answer') }
      specify { client.send(:perform, :get, 'path', { foo: 'bar' }).should == 'answer' }
    end

    context do
      before { stub_request(:get, "http://another.host/path.json?foo=bar&locale=en").
        to_return(:status => 200, :body => 'answer') }
      specify { client.send(:perform, :get, 'path', { foo: 'bar' }, { host: 'another.host' }).should == 'answer' }
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

  describe '.signature' do
    specify {NanoApi::Client.signature(12345).should == Digest::MD5.hexdigest("#{NanoApi.config.api_token}:12345")}
    specify {NanoApi::Client.signature(12345, 'hello', 'world').should == Digest::MD5.hexdigest("#{NanoApi.config.api_token}:12345:hello:world")}
    specify {NanoApi::Client.signature(12345, ['email']).should == Digest::MD5.hexdigest("#{NanoApi.config.api_token}:12345:email")}
  end
end
