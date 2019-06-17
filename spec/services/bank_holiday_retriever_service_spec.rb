require 'rails_helper'

RSpec.describe BankHolidayRetriever, vcr: { cassette_name: 'gov_uk_bank_holiday_api', allow_playback_repeats: true } do
  let(:group) { 'england-and-wales' }

  subject { described_class.new }

  describe '.dates' do
    it 'returns same as instance dates for group' do
      expect(described_class.dates).to eq(subject.dates(group))
    end
  end

  describe '#data' do
    it 'is a hash' do
      expect(subject.data).to be_a(Hash)
    end

    it 'has the expected basic structure' do
      expect(subject.data.keys).to include(group)
    end
  end

  describe '#dates' do
    let(:dates) { subject.dates(group) }
    it 'is an array' do
      expect(dates).to be_a(Array)
    end

    it 'contains date strings' do
      expect(Date.parse(dates.first)).to be_a(Date)
    end
  end
end
