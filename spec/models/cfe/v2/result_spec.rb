require 'rails_helper'

module CFE
  module V2
    RSpec.xdescribe Result, type: :model do
      let(:eligible_result) { create :cfe_v2_result }
      let(:not_eligible_result) { create :cfe_v2_result, :not_eligible }
      # let(:contibution_required_result) { create :cfe_v2_result, :contribution_required }
      #      #let(:no_additional_properties) { create :cfe_v2_result, :no_additional_properties }
      #      #let(:additional_property) { create :cfe_v2_result, :with_additional_properties }

      describe '#assessment_result' do
        context 'eligible' do
          it 'returns eligible' do
            expect(eligible_result.assessment_result).to eq 'eligible'
          end
        end

        context 'not_eligible' do
          it 'returns not_eligible' do
            expect(not_eligible_result.assessment_result).to eq 'not_eligible'
          end
        end

        context 'contribution_required' do
          it 'returns contribution_required' do
            expect(contibution_required_result.assessment_result).to eq 'contribution_required'
          end
        end
      end

      describe '#capital_contribution' do
        it 'returns the value of the capital contribution' do
          expect(contibution_required_result.capital_contribution).to eq 465.66
        end
      end

      describe '#additional_property?' do
        context 'present' do
          it 'returns true' do
            expect(additional_property.additional_property?).to be true
          end
        end
        context 'not present' do
          it 'returns false' do
            expect(no_additional_properties.additional_property?).to be false
          end
        end
        context 'present but zero' do
          it 'returns false' do
            expect(eligible_result.additional_property?).to be false
          end
        end
      end

      describe 'additional_property_value' do
        it 'returns the value of the first additional property' do
          expect(additional_property.additional_property_value).to eq 350_255.0
        end
      end

      describe 'additional_property_transaction_allowance' do
        it 'returns the transaction allowance for the first additional property' do
          expect(additional_property.additional_property_transaction_allowance).to eq(-12_550.0)
        end
      end

      describe 'additional_property_mortgage', skip: 'Need to define V2 cfe result factory with this trait' do
        it 'returns the mortgage for the first additional property' do
          expect(additional_property.additional_property_mortgage).to eq(-45_000.0)
        end
      end

      describe 'additional_property_assessed_equity' do
        it 'returns the assessed equity for the first additional property' do
          expect(additional_property.additional_property_assessed_equity).to eq 224_000.0
        end
      end
    end
  end
end
