require 'spec_helper'

describe NanoApi::Client do
  let(:rest_client){subject.send(:site)}
  let(:fake){ %r{^#{URI.join(NanoApi.config.search_server, path)}} }

  describe 'minimal prices matrices' do
    let(:search){1212}

    describe '#week_minimal_prices' do
      let(:direct_date){'date'}
      let(:return_date){'date_1'}
      let(:params){{
        search_id: search,
        direct_date: direct_date,
        return_date: return_date
      }}
      let(:path){'minimal_prices.json'}
      before do
        FakeWeb.register_uri :get, fake, body: '{date_1: {date2: price}}'
      end

      it 'should return json received from api call' do
        subject.week_minimal_prices(search, direct_date, return_date).should == '{date_1: {date2: price}}'
      end
    end

    describe '#month_minimal_prices' do
      let(:month){'month'}
      let(:params){{
        search_id: search,
        month: month
      }}
      let(:path){'month_minimal_prices.json'}
      before do
        FakeWeb.register_uri :get, fake, body: '[price_1, price_2]'
      end

      it 'should return json received from api call' do
        subject.month_minimal_prices(search, month).should == '[price_1, price_2]'
      end
    end

    describe '#nearest_cities_prices' do
      let(:params){{
        search_id: search
      }}
      let(:path){'nearest_cities_prices.json'}
      before do
        FakeWeb.register_uri :get, fake, body: '[price_1, price_2]'
      end

      it 'should return json received from api call' do
        subject.nearest_cities_prices(search).should == '[price_1, price_2]'
      end
    end
  end

  describe '#latest_prices' do
    let(:path){'latest_prices.json'}
    let(:params){{
      origin: 'MOW',
      origin_iata: 'MOW',
      destination: 'TH',
      destination_iata: '',
      beginning_of_period: '2013-05-01',
      period_type: 'Month',
      one_way: false,
      trip_duration: 3,
      sorting: 'price',
      page: 1,
      currency: 'rub'
    }}

    let(:controller) do
      mock(marker: '12345', session: {}, request: mock(host: 'test.com', env: {}, remote_ip: '127.1.1.1'))
    end

    subject { NanoApi::Client.new controller }

    it 'should pass correct params' do
      api_call_params = params.merge(show_to_affiliates: true, per_page: NanoApi::Client::LATEST_PRICES_PER_PAGE)
      subject.should_receive(:get).with('latest_prices', api_call_params)

      subject.latest_prices(params)
    end

    it 'should return json received from api call' do
      FakeWeb.register_uri :get, fake, body: '{"prices": [1, 2, 3]}'

      subject.latest_prices(params).should == {prices: [1, 2, 3]}
    end

    it 'allows override show_to_affiliates and per_page params' do
      subject.should_receive(:get).with('latest_prices', hash_including(show_to_affiliates: false, per_page: 20))

      subject.latest_prices(params.merge(show_to_affiliates: false, per_page: 20))
    end
  end
end
