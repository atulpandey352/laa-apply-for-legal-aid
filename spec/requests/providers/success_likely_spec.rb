require 'rails_helper'

RSpec.describe Providers::SuccessLikelyController, type: :request do
  let(:merits_assessment) { create :merits_assessment }
  let(:legal_aid_application) { create :legal_aid_application, merits_assessment: merits_assessment }
  let(:login) { login_as legal_aid_application.provider }

  before { login }

  describe 'GET /providers/applications/:id/success_likely' do
    subject { get providers_legal_aid_application_success_likely_index_path(legal_aid_application) }

    it 'renders successfully' do
      subject
      expect(response).to have_http_status(:ok)
    end

    context 'when the provider is not authenticated' do
      let(:login) { nil }
      before { subject }
      it_behaves_like 'a provider not authenticated'
    end
  end

  describe 'POST /providers/applications/:legal_aid_application_id/vehicle' do
    let(:success_prospect) { :poor }
    let(:merits_assessment) { create :merits_assessment, success_prospect: success_prospect, success_prospect_details: 'details' }
    let(:success_likely) { 'true' }
    let(:params) do
      { merits_assessment: { success_likely: success_likely } }
    end
    let(:submit_button) { {} }
    let(:next_url) { providers_legal_aid_application_check_merits_answers_path(legal_aid_application) }

    subject do
      post(
        providers_legal_aid_application_success_likely_index_path(legal_aid_application),
        params: params.merge(submit_button)
      )
    end

    it 'sets success_likely to true' do
      expect { subject }.to change { merits_assessment.reload.success_likely }.to(true)
    end

    it 'sets success_prospect to likely' do
      expect { subject }.to change { merits_assessment.reload.success_prospect }.to('likely')
    end

    it 'sets success_prospect_details to nil' do
      expect { subject }.to change { merits_assessment.reload.success_prospect_details }.to(nil)
    end

    it 'redirects to next page' do
      subject
      expect(response).to redirect_to(next_url)
    end

    context 'false is selected' do
      let(:next_url) { providers_legal_aid_application_success_prospects_path(legal_aid_application) }
      let(:success_likely) { 'false' }

      it 'sets success_likely to false' do
        expect { subject }.to change { merits_assessment.reload.success_likely }.to(false)
      end

      it 'does not change success_prospect' do
        expect { subject }.not_to change { merits_assessment.reload.success_prospect }
      end

      it 'does not change success_prospect_details' do
        expect { subject }.not_to change { merits_assessment.reload.success_prospect_details }
      end

      it 'redirects to next page' do
        subject
        expect(response).to redirect_to(next_url)
      end

      context 'success_prospect was :likely' do
        let(:success_prospect) { :likely }

        it 'sets success_prospect to nil' do
          expect { subject }.to change { merits_assessment.reload.success_prospect }.to(nil)
        end
      end
    end

    context 'nothing is selected' do
      let(:params) { {} }

      it 'renders successfully' do
        subject
        expect(response).to have_http_status(:ok)
      end

      it 'displays error' do
        subject
        expect(response.body).to include('govuk-error-summary')
      end
    end

    context 'Form submitted using Save as draft button' do
      let(:submit_button) { { draft_button: 'Save as draft' } }

      it "redirects provider to provider's applications page" do
        subject
        expect(response).to redirect_to(providers_legal_aid_applications_path)
      end

      it 'sets the application as draft' do
        expect { subject }.to change { legal_aid_application.reload.draft? }.from(false).to(true)
      end

      it 'updates the model' do
        subject
        merits_assessment.reload
        expect(merits_assessment.success_likely).to eq(true)
        expect(merits_assessment.success_prospect).to eq('likely')
      end
    end
  end
end
