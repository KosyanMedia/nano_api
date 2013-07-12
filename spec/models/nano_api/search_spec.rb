require 'spec_helper'

describe NanoApi::Search do
  let(:search){Fabricate :nano_api_search}
  subject { search }

  [:origin, :destination].each do |place|
    describe "##{place}" do
      context do
        before{
          search.send("#{place}_name=", 'Foo')
          search.send("#{place}_iata=", 'Bar')
        }
        specify{search.send(place).should == {name: 'Foo', iata: 'Bar'}}
      end

      context do
        before{
          search.send("#{place}_name=", 'Foo')
          search.send("#{place}_iata=", nil)
        }
        specify{search.send(place).should == {name: 'Foo'}}
      end

      context do
        before{
          search.send("#{place}_name=", nil)
          search.send("#{place}_iata=", 'Bar')
        }
        specify{search.send(place).should == {name: 'Bar', iata: 'Bar'}}
      end
    end
  end

  describe '#origin=' do
    context 'hash value' do
      before{search.origin = {name: 'Foo', iata: 'Bar'}}
      specify{search.origin_name.should == 'Moscow'}
      specify{search.origin_iata.should == 'Bar'}
    end
    context 'string value' do
      before{search.origin = 'Hello'}
      specify{search.origin_name.should == 'Hello'}
      specify{search.origin_iata.should be_nil}
    end
  end

  describe '#destination=' do
    context 'hash value' do
      before{search.destination = {name: 'Foo', iata: 'Bar'}}
      specify{search.destination_name.should == 'London'}
      specify{search.destination_iata.should == 'Bar'}
    end
    context 'string value' do
      before{search.destination = 'Hello'}
      specify{search.destination_name.should == 'Hello'}
      specify{search.destination_iata.should be_nil}
    end
  end

  describe '#attributes_for_search' do
    specify { described_class.new.attributes_for_search.keys.should =~ [
      :depart_date, :return_date, :range, :one_way, :trip_class, :adults, :children, :infants
    ] }
    specify { described_class.new(origin_iata: 'MOW').attributes_for_search.keys.should =~ [
      :depart_date, :return_date, :range, :one_way, :trip_class, :adults, :children, :infants, :origin_iata, :origin_name
    ] }
  end

  describe '#attributes_for_cookies' do
    specify { described_class.new.attributes_for_cookies.keys.should =~ [
      :depart_date, :return_date, :range, :one_way, :trip_class, :adults, :children, :infants
    ] }
    specify { described_class.new(origin_iata: 'MOW').attributes_for_cookies.keys.should =~ [
      :depart_date, :return_date, :range, :one_way, :trip_class, :adults, :children, :infants, :origin_iata, :origin_name
    ] }
  end

  describe 'names defaults' do
    let(:search) { Fabricate :nano_api_search_iatas }

    context do
      its(:origin_name){ should == search.origin_iata }
      its(:destination_name){ should == search.destination_iata }
    end

    context do
      before { search.update_attributes(origin_name: 'London', destination_name: 'Moscow') }
      its(:origin_name){ should == 'London' }
      its(:destination_name){ should == 'Moscow' }
    end
  end

  describe 'names defaults' do
    let(:origin_iata){'MOW'}
    let(:destination_iata){'LON'}
    let(:search) { Fabricate :nano_api_search_iatas, origin_iata: origin_iata, destination_iata: destination_iata }

    context do
      before do
        stub_http_request(
          :get,
          NanoApi.config.data_server + "/api/places?code=#{destination_iata}&locale=#{I18n.locale}"
        ).to_return(
          body: "[{\"_type\": \"City\", \"code\": \"#{destination_iata}\", \"name\": \"London1\"}]"
        )
      end

      its(:origin_name){ should == origin_iata }
      its(:destination_name){ should == 'London1' }
    end
  end

end
