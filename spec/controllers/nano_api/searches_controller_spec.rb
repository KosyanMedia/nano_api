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
        }.stringify_keys!
      }}

      context do
        before{get :new, use_route: :nano_api}
        specify{assigns[:search].attributes.should include({'origin_name' => 'Moscow', 'origin_iata' => 'MOW'})}
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
        }.stringify_keys!}
        before do
          cookies.stub(:[]).with(:marker).and_return('direct')
          cookies.stub(:[]).with(:search_params) do
            {
              params_attributes: {
                origin: { iata: 'BKK' },
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
      NanoApi::Client.any_instance.stub(:search).and_return('{tickets: [{test: 1}, {test: 2}]}')
    end

    context do
      before do
        post :create, use_route: :nano_api
      end

      it 'should be success' do
        response.content_type.should == Mime::JSON
        response.should be_success
        response.body.should == '{tickets: [{test: 1}, {test: 2}]}'
      end

      specify{cookies[:search_params].should == assigns[:search].search_params.to_json}
    end

    context do
      it 'should increment current referrer searches count' do
        request.env['HTTP_REFERER'] = 'http://ya.ru'
        get :new, { use_route: :nano_api }
        session[:current_referer][:search_count].should == 0

        post :create, use_route: :nano_api
        session[:current_referer][:search_count].should == 1

        request.env['HTTP_REFERER'] = 'http://ya.ru'
        post :create, use_route: :nano_api
        session[:current_referer][:search_count].should == 2

        request.env['HTTP_REFERER'] = 'http://google.com'
        post :create, use_route: :nano_api
        session[:current_referer][:search_count].should == 1
      end
    end
  end

  describe 'show_hotels?' do
    before do
      controller.stub(:affiliate).and_return(affiliate)
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
  end
end
