require 'spec_helper'

describe NanoApi::Client do
  let(:rest_client){subject.send(:site)}
  let(:response){'[{"iata": "SD", "name": "Airline 1"}]'}
  let(:fake){ %r{^#{URI.join(NanoApi.config.search_server, path)}} }
  let(:path){'airlines_for_direction.json'}

  before do
    stub_http_request(:get, fake).to_return(body: response)
  end

  it 'should return list of airlines for requested direction' do
    subject.airlines_for_direction('MOW', 'LED').should == response
  end
end
