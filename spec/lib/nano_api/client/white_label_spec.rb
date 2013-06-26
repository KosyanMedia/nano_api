require 'spec_helper'

describe NanoApi::Client do
  describe '#white_label' do
    before { stub_request(:get, "http://test.te/white_labels/show.json?locale=en&signature=97e7f3e73591ab7fe0bb115244b09b3d&white_label_host=example.com").
      to_return(:status => 200, :body => '{ "config": {} }') }
    specify { subject.white_label('example.com').should == { 'config' => {} } }
  end
end
