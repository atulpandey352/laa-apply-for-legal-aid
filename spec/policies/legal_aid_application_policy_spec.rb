require 'rails_helper'

RSpec.describe LegalAidApplicationPolicy do
  # let(:passported_permission) { create :permission, :passported }
  # let(:non_passported_permission) { create :permission, :non_passported }

  subject { LegalAidApplicationPolicy.new(provider, legal_aid_application) }

  let(:controller_actions) do
    %i[
      index
      new
      show
      update
      destroy
      create
      remove_transaction_type
      continue
      reset
      show_submitted_application
    ]
  end

  context 'Provider from another firm' do
    let(:legal_aid_application) { create(:legal_aid_application) }
    let(:provider) { create(:provider) }

    it 'should not allow any action' do
      controller_actions.each do |action|
        expect(subject).not_to permit(action)
      end
    end
  end

  context 'provider who created the application' do
    let(:legal_aid_application) { create(:legal_aid_application) }
    let(:provider) { legal_aid_application.provider }

    context 'application not yet checked benefits' do
      it 'should permit all actions' do
        controller_actions.each do |action|
          expect(subject).to permit(action)
        end
      end
    end

    context 'application is passported' do
      let(:legal_aid_application) { create(:legal_aid_application, :with_positive_benefit_check_result) }
      context 'provider has passported rights' do
        before { provider.permissions << passported_permission }

        it 'permits all actions' do
          controller_actions.each do |action|
            expect(subject).to permit(action)
          end
        end
      end

      context 'provider does not have passported rights' do
        it 'does not permit any actions' do
          controller_actions.each do |action|
            expect(subject).not_to permit(action)
          end
        end
      end
    end

    context 'application is non-passported' do
      let(:legal_aid_application) { create(:legal_aid_application, :with_negative_benefit_check_result) }
      context 'provider has non-passported rights' do
        before { provider.permissions << non_passported_permission }

        it 'permits all actions' do
          controller_actions.each do |action|
            expect(subject).to permit(action)
          end
        end
      end

      context 'provider does not have non-passported rights' do
        it 'does not permit any actions' do
          controller_actions.each do |action|
            expect(subject).not_to permit(action)
          end
        end
      end
    end
  end
end
