require 'spec_helper'

describe NanoApi::Controller::Markerable do
  context do
    include RSpec::Rails::ControllerExampleGroup

    controller do
      include NanoApi::Controller::Markerable

      def new
        render :nothing => true
      end
    end

    let(:affiliate_attributes){{}}
    before do
      controller.stub(affiliate: affiliate_attributes)
    end

    describe '.marker' do
      [ {:marker => 'referer'}, {:ref => 'referer'} ].each do |param|
        specify do
          get :new, param
          controller.send(:marker).should == 'referer'
        end
      end
    end

    describe 'should save new marker in cookies' do
      [ {:marker => 'referer'}, {:ref => 'referer'} ].each do |param|
        specify do
          get :new, param
          controller.send(:cookies)[:marker].should == 'referer'
          response.status.should == 301
        end
      end
    end

    context 'marker is NOT given in request params' do
      describe 'should save default marker to cookies when marker in cookies is blank' do
        specify do
          get :new
          controller.send(:cookies)[:marker].should == 'direct'
        end
      end

      describe 'should NOT save default marker to cookies when marker in cookies is NOT blank' do
        specify do
          get :new, marker: 'test'
          get :new
          controller.send(:cookies)[:marker].should_not == 'direct'
        end
      end
    end

    context 'new marker is affiliate marker' do
      it 'should update cookies' do
        get :new, :marker => 'test'
        get :new, :marker => '12345'

        controller.send(:cookies)[:marker].should == '12345'
      end

      it 'should update affiliate cookies' do
        get :new, :marker => '12346'
        get :new, :marker => '12345'

        controller.send(:cookies)[:marker].should == '12345'
      end
    end

    context 'new marker is not affiliate marker' do
      it 'should update cookies' do
        get :new, :marker => 'test'
        get :new, :marker => 'test1'

        controller.send(:cookies)[:marker].should == 'test1'
      end

      it 'should not update affiliate cookies' do
        get :new, :marker => '12345'
        get :new, :marker => 'test1'

        controller.send(:cookies)[:marker].should == '12345'
      end
    end

    it 'should not update cookie expired time for same affiliate requests' do
      get :new, :marker => '12345'

      controller.send(:cookies).should_not_receive(:[]=).with(:marker, an_instance_of(Hash))
      get :new, :marker => '12345'
    end


    shared_examples_for :marker_cookie_setter do
      before(:all){Timecop.freeze}
      after(:all){Timecop.return}
      let(:marker){'test'}

      it 'should set cookie with correct cookie params' do
        controller.send(:cookies).should_receive(:[]=).with(:marker, cookie_params)
        get :new, :marker => marker
      end
    end

    context 'non affiliate marker' do
      let(:affiliate_attributes){nil}
      let(:cookie_params){{value: marker, domain: 'test.host', expires: 30.days.from_now}}

      it_should_behave_like :marker_cookie_setter
    end

    context 'affiliate marker with custom marker life time' do
      let(:affiliate_attributes){{marker_life_time_in_days: 1}}
      let(:cookie_params){{value: marker, domain: 'test.host', expires: 1.day.from_now}}

      it_should_behave_like :marker_cookie_setter
    end
  end
end
