require 'spec_helper'

describe NanoApi::Client do
  let(:rest_client){subject.send(:site)}
  let(:fake){ %r{^#{URI.join(NanoApi.config.search_server, path)}} }

  describe '.auto_complete_places' do
    let(:path){'places_ru.json'}

    context 'standard api call' do
      before do
        I18n.locale = :ru
        stub_http_request(:get, fake).to_return(body: '[place1, place2]')
      end

      it 'should return parsed json' do
        subject.auto_complete_place('term').should == '[place1, place2]'
      end
    end

    context 'handle api errors' do
      before do
        stub_http_request(:get, fake).to_return(status: [400, 'Bad Request'])
      end

      it 'should return parsed json' do
        subject.auto_complete_place('term').should be_nil
      end
    end
  end

  describe '.ip_to_city' do
    let(:path){'places/ip_to_places_en.json'}

    let(:places){[{
      iata: 'MOW',
      name: 'Moscow',
      coordinates: [15.28, 100.3],
      index_strings: ['mow'],
      airport_name: 'Domodedovo'
    }, {
      iata: 'TYL',
      name: 'Tula',
      coordinates: [16.28, 101.3],
      index_strings: ['tula'],
      airport_name: 'Tula'
    }]}

    before do
      I18n.locale = :en
      stub_http_request(:get, fake).to_return(body: places.to_json)
    end

    it 'should return estimated duration in seconds, from api call' do
      subject.geoip('1.1.1.1').should == {
        iata: 'MOW',
        name: 'Moscow',
        coordinates: [15.28, 100.3],
        index_strings: ['mow'],
        airport_name: 'Domodedovo'
      }
    end
  end
end
