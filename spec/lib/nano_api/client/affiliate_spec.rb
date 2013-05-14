require 'spec_helper'

describe NanoApi::Client do
  describe '.affiliate' do
    let(:marker){'11501.lo'}
    let(:clean_marker){'11501'}
    let(:signature){'test_signature'}
    let(:status){['200', 'Ok']}
    before do
      subject.stub(:affilate_signature).and_return(signature)
      subject.stub(:marker).and_return(marker)
      stub_http_request(
        :get,
        NanoApi.config.search_server + '/affiliates/%d.json?locale=en&signature=%s' % [clean_marker, signature]
      ).to_return(
        body: response_body,
        status: status
      )
    end

    context 'standard api call' do
      let(:affiliate_data){{
        affiliate: {
          id: 234,
          email: 'affiliate@aviasales.ru',
          created_at: '2011-08-10T06:08:35Z',
          info: {
            marker: 11501,
            name: 'Specavia',
            website: 'http://specavia.ru',
            subscribed: false,
            min_payout: 10000,
            show_hotels: true,
            internal: false,
            marker_life_time_in_days: 60
          }
        }
      }}
      let(:response_body){affiliate_data.to_json}

      it 'should return parsed json' do
        response = affiliate_data[:affiliate].merge(affiliate_data[:affiliate].delete(:info)).stringify_keys!

        subject.affiliate.should == response
      end
    end

    context 'handle empty response' do
      let(:response_body){'{}'}

      it 'should return nil' do
        subject.affiliate.should be_nil
      end
    end

     context 'handle forbidden' do
        let(:response_body){'{error: "your ip is banned"}'}
        let(:status){['403', 'Forbidden']}

        it 'should return nil' do
          subject.affiliate.should be_nil
        end
      end

  end
end
