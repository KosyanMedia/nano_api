require 'spec_helper'

describe NanoApi::Client do
  let(:rest_client){subject.send(:site)}
  let(:response){'{success: true}'}
  let(:fake){ URI.join(NanoApi.config.search_server, path) }
  let(:path){'/ui_events/mass_create.json'}

  before do
    stub_http_request(:post, fake.to_s).to_return(body: response)
  end

  it 'should return list of airlines for requested direction' do
    subject.ui_events_mass_create({hello: 'world'}).should == response
  end
end
