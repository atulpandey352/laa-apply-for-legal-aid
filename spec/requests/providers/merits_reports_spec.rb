require 'rails_helper'

RSpec.describe Providers::MeritsReportsController, type: :request do
  let(:legal_aid_application) { create :legal_aid_application, :with_proceeding_types, :with_everything, :assessment_submitted }
  let(:login_provider) { login_as legal_aid_application.provider }
  let!(:submission) { create :submission, legal_aid_application: legal_aid_application }
  let(:before_subject) { nil }

  describe 'GET /providers/applications/:legal_aid_application_id/merits_report' do
    subject { get providers_legal_aid_application_merits_report_path(legal_aid_application, debug: true) }

    before do
      login_provider
      before_subject
      subject
    end

    it 'renders successfully' do
      expect(response).to have_http_status(:ok)
    end

    it 'displays the application ref number' do
      expect(unescaped_response_body).to include(legal_aid_application.application_ref)
    end

    it 'displays the CCMS case reference' do
      expect(unescaped_response_body).to include(submission.case_ccms_reference)
    end

    context 'when not authenticated' do
      let(:login_provider) { nil }
      it_behaves_like 'a provider not authenticated'
    end
  end
end
