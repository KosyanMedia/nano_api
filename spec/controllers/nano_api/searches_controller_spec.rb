require 'spec_helper'

describe NanoApi::SearchesController do
  describe 'GET :new' do
    let!(:geoip_data){{iata: 'MOW', name: 'Moscow'}}
    let(:affiliate){nil}
    before do
      NanoApi::Client.any_instance.stub(:geoip).and_return(geoip_data)
      NanoApi::Client.any_instance.stub(:affiliate).and_return(affiliate)
    end

    it 'should be successful' do
      get :new, use_route: :nano_api
      response.should be_success
    end

    context 'search, cookies and affiliate' do
      let(:search){{
        search: {
          origin_iata: 'LED',
          destination_iata: 'LED',
          depart_date: Date.parse('2012-04-01'),
          return_date: Date.parse('2012-04-01'),
          trip_class: 0,
          adults: 1
        }
      }}

      context do
        before{get :new, use_route: :nano_api}
        specify{assigns[:search].attributes.should include({origin_name: 'Moscow', origin_iata: 'MOW'})}
      end

      context 'unwrapped params without affiliate' do
        before{get :new, search[:search].merge(use_route: :nano_api)}

        specify{assigns[:search].attributes.should include search[:search]}
        specify{controller.send(:affiliate).should be_nil}
      end

      context 'wrapped params with affiliate' do
        let(:affiliate){{some_property: true}}

        before{get :new, search.merge(use_route: :nano_api)}

        specify{assigns[:search].attributes.should include search[:search]}
        specify{controller.send(:affiliate)[:some_property].should be_true}
      end

      context 'cookies default values' do
        let(:cookies_defaults){{
          origin_iata: 'MOW',
          destination_iata: 'LON'
        }}

        before do
          cookies.stub(:[]).with(:marker).and_return('direct')
          cookies.stub(:[]).with(:search_params) do
            {
              params_attributes: {
                origin: { iata: 'MOW' },
                destination: { iata: 'LON' }
              }
            }.to_json
          end
        end

        context do
          before{get :new, use_route: :nano_api}
          specify{assigns[:search].attributes.should include cookies_defaults}
        end

        context do
          before{get :new, search.merge(use_route: :nano_api)}
          specify{assigns[:search].attributes.should include search[:search]}
        end
      end
    end
  end

  describe 'GET :show' do
    let(:params){{
      search: {
        params_attributes: {
          origin_iata: 'LED',
          destination_iata: 'LED',
          depart_date: '2012-04-01',
          return_date: '2012-04-01',
          trip_class: 0,
          adults: 1
        }
      }
    }}

    before do
      NanoApi::Client.any_instance.stub(:search_params).with('1').and_return(params)
    end

    it 'should be successful' do
      get :show, id: 1, use_route: :nano_api
      response.should be_success
      response.should render_template(:new)
    end
  end

  describe 'POST :create' do
    before do
      NanoApi::Client.any_instance.stub(:search).and_return('{"search_id":123, tickets: [{test: 1}, {test: 2}]}')
      stub_http_request(:get, NanoApi.config.pulse_server + "?event=search&search_id=123&auid=")
    end

    context do
      before do
        post :create, use_route: :nano_api
      end

      it 'should be success' do
        response.content_type.should == Mime::JSON
        response.should be_success
        response.body.should == '{"search_id":123, tickets: [{test: 1}, {test: 2}]}'
        response.headers.should include({'X-Search-Id' => '123'})
      end

      specify{cookies[:search_params].should == assigns[:search].search_params.to_json}
    end
  end

  describe 'show_hotels?' do
    let(:params){{}}

    before do
      controller.stub(:affiliate).and_return(affiliate)
      controller.stub(:params).and_return(params)
    end

    context 'affiliate is nil' do
      let(:affiliate){nil}
      specify{controller.send(:show_hotels?).should be_true}
    end

    context 'affiliate not have key show_hotels' do
      let(:affiliate){{}}
      specify{controller.send(:show_hotels?).should be_true}
    end

    context 'affiliate show_hotels is true' do
      let(:affiliate){{:show_hotels => true}}
      specify{controller.send(:show_hotels?).should be_true}
    end

    context 'affiliate show_hotels is false' do
      let(:affiliate){{:show_hotels => false}}
      specify{controller.send(:show_hotels?).should be_false}
    end

    context 'affiliate show_hotels is false, parameter show_hotels is true' do
      let(:affiliate){{:show_hotels => false}}
      let(:params){{:show_hotels => 'true'}}
      specify{controller.send(:show_hotels?).should be_false}
    end

    context 'affiliate show_hotels is true, parameter show_hotels is false' do
      let(:affiliate){{:show_hotels => true}}
      let(:params){{:show_hotels => 'false'}}
      specify{controller.send(:show_hotels?).should be_false}
    end

    context 'affiliate show_hotels is true, parameter show_hotels is 0' do
      let(:affiliate){{:show_hotels => true}}
      let(:params){{:show_hotels => '0'}}
      specify{controller.send(:show_hotels?).should be_true}
    end
  end

  describe 'show_hotels_type' do
    let(:params){{}}

    before do
      controller.stub(:affiliate).and_return(affiliate)
      controller.stub(:params).and_return(params)
    end

    context 'affiliate is nil' do
      let(:affiliate){nil}
      specify{controller.send(:show_hotels_type).should == :without_hotels}
    end

    context 'affiliate not have key show_hotels_type' do
      let(:affiliate){{}}
      specify{controller.send(:show_hotels_type).should == :without_hotels}
    end

    context 'affiliate show_hotels is :original_host' do
      let(:affiliate){{:show_hotels_type => :original_host}}
      specify{controller.send(:show_hotels_type).should == :original_host}
    end

  end

  describe '#track_search' do
    let(:search_id){ 123 }
    let(:auid){ :test_string }
    let(:marker){ '123.фыва и олдж' }
    let(:request_uri){ NanoApi.config.pulse_server + "/?event=search&search_id=#{search_id}&auid=#{auid}&marker=#{URI.encode(marker)}" }

    before do
      stub_http_request(:get, request_uri)
      controller.stub(:marker).and_return(marker)
    end

    it "sends get request" do
      RestClient::Request.should_receive(:execute).with(
        method: :get,
        url: request_uri,
        timeout: 3.seconds,
        open_timeout: 3.seconds
      )
      controller.send(:track_search, search_id, auid)
    end
  end

  describe '#get_search_id' do
    let(:json){ JSON.dump({search_id: search_id}) }
    subject{ controller.send(:get_search_id, json) }

    context 'with invalid value' do
      let(:search_id){ 'abcd' }
      it{ should be_empty }
    end

    context 'with uuid' do
      let(:search_id){ '442966fd-81fb-4415-91ab-0797849a7327' }
      it{ should == search_id }
    end

    context 'with integer id' do
      let(:search_id){ 12345 }
      it{ should == search_id.to_s }
    end
  end
end
