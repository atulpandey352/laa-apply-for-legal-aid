require 'rails_helper'

RSpec.describe Providers::HasOtherDependantsController, type: :request do
  let(:legal_aid_application) { create :legal_aid_application, :with_applicant }
  let(:provider) { legal_aid_application.provider }

  before do
    login_as provider
    subject
  end

  describe 'GET /providers/:application_id/has_other_dependants' do
    subject { get providers_legal_aid_application_has_other_dependants_path(legal_aid_application) }

    it 'returns http success' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PATCH /providers/:application_id/has_other_dependants' do
    let(:params) do
      {
        other_dependant: other_dependant
      }
    end

    subject { patch providers_legal_aid_application_has_other_dependants_path(legal_aid_application), params: params }

    context 'choose yes' do
      let(:other_dependant) { 'yes' }

      it 'redirects to the page to add another dependant' do
        expect(response).to redirect_to(new_providers_legal_aid_application_dependant_path(legal_aid_application))
      end
    end

    context 'choose no' do
      let(:other_dependant) { 'no' }

      it 'redirects to the outgoings summary page' do
        expect(response).to redirect_to(providers_legal_aid_application_outgoings_summary_index_path(legal_aid_application))
      end
    end

    context 'choose something else' do
      let(:other_dependant) { 'not sure' }

      it 'show errors' do
        expect(response.body).to include(I18n.t('providers.has_other_dependants.show.error'))
      end
    end

    context 'choose nothing' do
      let(:params) {}

      it 'show errors' do
        expect(response.body).to include(I18n.t('providers.has_other_dependants.show.error'))
      end
    end
  end
end
