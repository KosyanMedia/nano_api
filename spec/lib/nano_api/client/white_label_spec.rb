require 'spec_helper'

describe NanoApi::Client do
  describe '#white_label' do
    before { stub_request(:get, "http://test.te/white_labels/show.json?locale=en&signature=97e7f3e73591ab7fe0bb115244b09b3d&white_label_host=example.com").
      to_return(:status => 200, :body => '{ "white_label": { "config": {} } }') }
    specify { subject.white_label('example.com').should == { 'config' => {} } }

    context 'preview' do
      before { stub_request(:get, "http://test.te/white_labels/show.json?locale=en&preview=1&signature=aa12401fb3dba51d16390777055f63b1&white_label_host=example.com").
        to_return(:status => 200, :body => '{ "white_label": { "config": {} } }') }
      specify { subject.white_label('example.com', '1').should == { 'config' => {} } }
    end
  end
end
