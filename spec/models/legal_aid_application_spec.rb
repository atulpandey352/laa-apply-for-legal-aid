require 'rails_helper'

RSpec.describe LegalAidApplication, type: :model do
  let(:legal_aid_application) { create :legal_aid_application }

  describe 'validations' do
    let(:attributes) { { proceeding_type_codes: %w[invalid_code1 invalid_code2] } }
    let(:legal_aid_application) { described_class.new(attributes) }
    context 'when invalid proceeding type codes are provided' do
      it 'contains an invalid error for proceeding type codes' do
        expect(legal_aid_application).not_to be_valid
        expect(legal_aid_application.errors[:proceeding_type_codes]).to match_array(['is invalid'])
      end
    end

    context 'when valid proceeding type codes are provided' do
      let!(:proceeding_types) { create_list(:proceeding_type, 2) }
      let(:proceeding_type_codes) { proceeding_types.map(&:code) }
      let(:attributes) { { proceeding_type_codes: proceeding_type_codes } }

      it 'will be valid' do
        expect(legal_aid_application).to be_valid
      end
    end
  end

  describe '#proceeding_type_codes=' do
    context 'when all the provded codes match existent proceeding types' do
      let!(:proceeding_types) { create_list(:proceeding_type, 2) }
      let(:proceeding_type_codes) { proceeding_types.map(&:code) }

      it 'assigns the provides codes' do
        expect {
          legal_aid_application.proceeding_type_codes = proceeding_type_codes
        }.to change { legal_aid_application.proceeding_type_codes }.from(nil).to(proceeding_type_codes)
      end

      it 'assign all providing types matching the codes' do
        expect(legal_aid_application.proceeding_types).to be_empty
        legal_aid_application.proceeding_type_codes = proceeding_type_codes
        expect(legal_aid_application.proceeding_types).to eq(proceeding_types)
      end
    end

    context 'when not all the provided codes match existent proceeding types' do
      let!(:proceeding_type) { create(:proceeding_type) }
      let(:proceeding_type_codes) { [proceeding_type.code, 'non-existent-code'] }

      it 'assigns the provides codes' do
        expect {
          legal_aid_application.proceeding_type_codes = proceeding_type_codes
        }.to change { legal_aid_application.proceeding_type_codes }.from(nil).to(proceeding_type_codes)
      end

      it 'assign only the providing types matching the codes' do
        expect(legal_aid_application.proceeding_types).to be_empty
        legal_aid_application.proceeding_type_codes = proceeding_type_codes
        expect(legal_aid_application.proceeding_types).to eq([proceeding_type])
      end
    end
  end

  describe '#add_benefit_check_result' do
    let(:benefit_check_service) { spy(BenefitCheckService) }
    let(:benefit_check_response) do
      {
        benefit_checker_status: Faker::Lorem.word,
        confirmation_ref: SecureRandom.hex
      }
    end

    before do
      legal_aid_application.save!
      allow(BenefitCheckService).to receive(:new).with(legal_aid_application).and_return(benefit_check_service)
    end

    it 'creates a check_benefit_result with the right values' do
      expect(benefit_check_service).to receive(:call).and_return(benefit_check_response)

      legal_aid_application.add_benefit_check_result
      expect(legal_aid_application.benefit_check_result.result).to eq(benefit_check_response[:benefit_checker_status])
      expect(legal_aid_application.benefit_check_result.dwp_ref).to eq(benefit_check_response[:confirmation_ref])
    end
  end

  describe 'benefit_check_result_needs_updating?' do
    let!(:legal_aid_application) { create :legal_aid_application, :with_applicant }
    let(:applicant) { legal_aid_application.applicant }
    it 'is true if no benefit check results' do
      expect(legal_aid_application).to be_benefit_check_result_needs_updating
    end

    context 'with up to date benefit check results' do
      let!(:benefit_check_result) { create :benefit_check_result, legal_aid_application: legal_aid_application }

      it 'returns false' do
        expect(legal_aid_application).not_to be_benefit_check_result_needs_updating
      end

      context 'but later, applicant first name updated' do
        before { applicant.update(first_name: Faker::Name.first_name) }

        it 'returns true' do
          expect(legal_aid_application).to be_benefit_check_result_needs_updating
        end
      end

      context 'but later, state changes' do
        before do
          legal_aid_application.check_your_answers!
        end

        it 'returns false' do
          expect(legal_aid_application).not_to be_benefit_check_result_needs_updating
        end
      end
    end
  end

  describe '#generate_secure_id' do
    let(:legal_aid_application) { create :legal_aid_application }
    let(:secure_data) { SecureData.last }

    subject { legal_aid_application.generate_secure_id }

    it 'generates a new secure data object' do
      expect { subject }.to change { SecureData.count }.by(1)
    end

    it 'returns the generated id' do
      expect(subject).to eq(secure_data.id)
    end

    it 'generates data that can be used to find legal_aid_application' do
      data = SecureData.for(subject)[:legal_aid_application]
      expect(data).to be_present
      expect(described_class.find_by(data)).to eq(legal_aid_application)
    end
  end

  describe '.find_by_secure_id!' do
    let(:legal_aid_application) { create :legal_aid_application }
    let(:secure_id) { legal_aid_application.generate_secure_id }

    it 'should return matching legal aid legal_aid_application' do
      expect(described_class.find_by_secure_id!(secure_id)).to eq(legal_aid_application)
    end
  end

  describe 'state machine' do
    subject(:legal_aid_application) { create(:legal_aid_application) }

    it 'is created with a default state of "initiated"' do
      expect(legal_aid_application.state).to eq('initiated')
    end
  end

  describe '#shared_ownership?' do
    subject(:legal_aid_application) { create(:legal_aid_application, shared_ownership: shared_ownership_reason) }

    context 'when applicant owns a share of a property' do
      let(:shared_ownership_reason) { LegalAidApplication::SHARED_OWNERSHIP_YES_REASONS.first }

      it 'return true that the applicant owns a share of a property' do
        expect(legal_aid_application.shared_ownership?).to eq true
      end
    end

    context 'when applicant is the sole owner of a property' do
      let(:shared_ownership_reason) { LegalAidApplication::SHARED_OWNERSHIP_NO_REASONS.first }
      it 'return true that the applicant owns a share of a property' do
        expect(legal_aid_application.shared_ownership?).to eq false
      end
    end
  end
end
