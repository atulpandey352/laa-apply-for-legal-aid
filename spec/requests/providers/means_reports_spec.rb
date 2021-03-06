require 'rails_helper'

RSpec.describe Providers::MeansReportsController, type: :request do
  include ActionView::Helpers::NumberHelper

  let(:legal_aid_application) { create :legal_aid_application, :with_proceeding_types, :with_everything, :with_cfe_v2_result, :assessment_submitted }
  let(:login_provider) { login_as legal_aid_application.provider }
  let!(:submission) { create :submission, legal_aid_application: legal_aid_application }
  let(:cfe_result) { legal_aid_application.cfe_result }
  let(:before_subject) { nil }

  describe 'GET /providers/applications/:legal_aid_application_id/means_report' do
    subject { get providers_legal_aid_application_means_report_path(legal_aid_application, debug: true) }

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

    it 'displays the total capital assessed' do
      expect(unescaped_response_body).to include(number_to_currency(cfe_result.total_capital))
    end

    it 'displays the capital lower limit' do
      expect(unescaped_response_body).to include('£3000.00')
    end

    it 'displays the capital upper limit' do
      expect(unescaped_response_body).to include('£8000.00')
    end

    it 'displays the capital contribution' do
      expect(unescaped_response_body).to include(number_to_currency(cfe_result.capital_contribution))
    end

    context 'when not authenticated' do
      let(:login_provider) { nil }
      it_behaves_like 'a provider not authenticated'
    end
  end
end
