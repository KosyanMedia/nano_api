require 'spec_helper'

describe NanoApi::SearchIdParser do
  subject { described_class }
  describe '.parse' do
    specify { subject.parse('MOW1005LONb1').params[:with_request].should be_true }

    specify { subject.parse('MOW1005LONb1').params[:range].should be_false }
    specify { subject.parse('MOW1005LONfb1').params[:range].should be_true }

    specify { subject.parse('MOW1005LONf1').params[:trip_class].should == 0 }
    specify { subject.parse('MOW1005LONfb1').params[:trip_class].should == 1 }

    specify { subject.parse('MOW1005LONfb2').params[:passengers].should == {adults: 2, children: 0, infants: 0} }
    specify { subject.parse('MOW1005LON200532').params[:passengers].should == {adults: 3, children: 2, infants: 0} }
    specify { subject.parse('MOW1005LON2005321').params[:passengers].should == {adults: 3, children: 2, infants: 1} }

    context 'when the day is not yet over in -12:00 timezone and there is the new year' do
      before { Timecop.freeze( Time.new(2014, 1, 1, 14, 59, 59, '+03:00') ) }
      specify { subject.parse('MOW3112LON1').params[:segments][0][:date].should == Date.new(2013, 12, 31) }
    end

    context 'when the day is not yet over in -12:00 timezone and there is no new year' do
      before { Timecop.freeze( Time.new(2013, 5, 10, 14, 59, 59, '+03:00') ) }
      specify { subject.parse('MOW0905LON1').params[:segments][0][:date].should == Date.new(2013, 5, 9) }
    end

    context 'when the day is already over in -12:00 timezone and there is the new year' do
      before { Timecop.freeze( Time.new(2014, 1, 1, 15, 0, 0, '+03:00') ) }
      specify { subject.parse('MOW3112LON1').params[:segments][0][:date].should == Date.new(2014, 12, 31) }
    end

    context 'when the day is already over in -12:00 timezone and there is no new year' do
      before { Timecop.freeze( Time.new(2013, 5, 10, 15, 0, 0, '+03:00') ) }
      specify { subject.parse('MOW0905LON1').params[:segments][0][:date].should == Date.new(2014, 5, 9) }
    end

    context do
      before { Timecop.freeze( Time.new(2013, 1, 1) ) }

      specify do
        subject.parse('MOW1005LON2005LED1').params[:segments].should == [
          { origin: { iata: 'MOW' }, destination: { iata: 'LON' }, date: Date.new(2013, 5, 10) },
          { origin: { iata: 'LON' }, destination: { iata: 'LED' }, date: Date.new(2013, 5, 20) }
        ]
      end

      specify do
        subject.parse('MOW1005LONLED20051').params[:segments].should == [
          { origin: { iata: 'MOW' }, destination: { iata: 'LON' }, date: Date.new(2013, 5, 10) },
          { origin: { iata: 'LED' }, destination: { iata: 'MOW' }, date: Date.new(2013, 5, 20) }
        ]
      end

      specify do
        subject.parse('CMOW1005LON-CLED2005AROV1').params[:segments].should == [
          { origin: { iata: 'MOW', type: 'city' }, destination: { iata: 'LON' }, date: Date.new(2013, 5, 10) },
          {
            origin: { iata: 'LED', type: 'city' },
            destination: { iata: 'ROV', type: 'airport' }, date: Date.new(2013, 5, 20)
          }
        ]
      end

      it 'is case insensitive' do
        subject.parse('amow1005lonFB2').params.should include(
          passengers: {adults: 2, children: 0, infants: 0},
          range: true,
          trip_class: 1,
          segments: [{
            origin: { iata: 'MOW', type: 'airport'},
            destination: { iata: 'LON' },
            date: Date.new(2013, 05, 10) }
          ]
        )
      end
    end

    it('fails to parse a segment without destination') { subject.parse('MOW10051').should be_nil }
    it('fails to parse if there is no roundtrip date and the preceeding path part is dateless') do
      subject.parse('MOW1005LON-LED1').should be_nil
    end
    it('fails to parse two dateless path parts in a row') { subject.parse('MOW1005LON-LED-ROV20051').should be_nil }
    it('fails to parse an unknown type code') { subject.parse('FMOW1005LON-CLED2005AROV1').should be_nil }
    it('fails to parse an invalid date') { subject.parse('MOW2020LON1').should be_nil }
  end
end
