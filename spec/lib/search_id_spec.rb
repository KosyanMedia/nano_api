require 'spec_helper'

describe NanoApi::SearchId do
  subject { described_class }
  describe '.parse' do
    specify { subject.parse('MOW1005LONb1').params[:with_request].should be_true }

    specify { subject.parse('MOW1005LON1').params[:trip_class].should == 'Y' }
    specify { subject.parse('MOW1005LONb1').params[:trip_class].should == 'C' }
    specify { subject.parse('MOW1005LONY1').params[:trip_class].should == 'Y' }
    specify { subject.parse('MOW1005LONC1').params[:trip_class].should == 'C' }
    specify { subject.parse('MOW1005LONW1').params[:trip_class].should == 'W' }
    specify { subject.parse('MOW1005LONF1').params[:trip_class].should == 'F' }
    specify { subject.parse('MOW1005LONy1').params[:trip_class].should == 'Y' }
    specify { subject.parse('MOW1005LONc1').params[:trip_class].should == 'C' }
    specify { subject.parse('MOW1005LONw1').params[:trip_class].should == 'W' }
    specify { subject.parse('MOW1005LONf1').params[:trip_class].should == 'F' }

    specify { subject.parse('MOW1005LONb2').params[:passengers].should == {adults: 2, children: 0, infants: 0} }
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
        subject.parse('amow1005lonB2').params.should include(
          passengers: {adults: 2, children: 0, infants: 0},
          trip_class: 'C',
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

  describe '.compose' do
    specify do
      subject.compose(
        segments: [
          { date: '2014-10-01', origin: { iata: 'AAA', type: 'city' }, destination: { iata: 'BBB', type: 'city' } },
          { date: '2014-10-03', origin: { iata: 'BBB', type: 'city' }, destination: { iata: 'CCC', type: 'airport' } },
          { date: '2015-01-01', origin: { iata: 'DDD', type: 'city' }, destination: { iata: 'AAA', type: 'city' } },
          { date: '2015-02-15', origin: { iata: 'AAA', type: 'airport' }, destination: { iata: 'BBB', type: 'city' } }
        ],
        trip_class: 'C',
        passengers: {
          adults: 3,
          children: 2,
          infants: 1
        }
      ).should == 'CAAA0110CBBB0310ACCC-CDDD0101CAAA-AAAA1502CBBBC321'
    end

    specify do
      subject.compose(
        segments: [
          { date: '2014-10-01', origin: { iata: 'AAA', type: 'city' }, destination: { iata: 'BBB', type: 'city' } },
          { date: '2014-10-03', origin: { iata: 'BBB', type: 'city' }, destination: { iata: 'AAA', type: 'city' } }
        ],
        trip_class: 'Y',
        passengers: {
          adults: 4,
          children: 0,
          infants: 3
        }
      ).should == 'CAAA0110CBBB0310Y403'
    end

    specify do
      subject.compose(
        segments: [
          { date: '2014-10-01', origin: { iata: 'AAA', type: 'city' }, destination: { iata: 'BBB', type: 'city' } }
        ],
        trip_class: 'W',
        passengers: {
          adults: 4,
          children: 3,
          infants: 0
        }
      ).should == 'CAAA0110CBBBW43'
    end

    specify do
      subject.compose(
        segments: [
          { date: '2014-10-01', origin: { iata: 'AAA', type: 'city' }, destination: { iata: 'BBB', type: 'city' } }
        ],
        trip_class: 'Y',
        passengers: {
          adults: 4,
          children: 0,
          infants: 0
        }
      ).should == 'CAAA0110CBBBY4'
    end
  end
end
