require 'rails_helper'

RSpec.describe 'citizen restrictions request', type: :request do
  let(:legal_aid_application) { create :legal_aid_application, :with_applicant }
  let!(:restrictions) { create_list :restriction, 3 }

  describe 'GET /providers/applications/:id/restrictions' do
    before { get providers_legal_aid_application_restrictions_path(legal_aid_application) }

    it 'returns http success' do
      expect(response).to have_http_status(:ok)
    end

    it 'displays the restriction name labels' do
      restrictions.map(&:label_name).each do |label|
        expect(unescaped_response_body).to include(label)
      end
    end
  end

  describe 'POST /citizens/restrictions' do
    let(:restriction_ids) { restrictions.pluck(:id) }
    let(:params) do
      {
        legal_aid_application_id: legal_aid_application.id,
        legal_aid_application: {
          restriction_ids: restriction_ids
        }
      }
    end
    subject { post providers_legal_aid_application_restrictions_path(legal_aid_application), params: params }

    it 'creates a mapping for each restriction' do
      expect { subject }.to change { LegalAidApplicationRestriction.count }.by(restrictions.count)
    end

    context 'after success' do
      before do
        subject
        legal_aid_application.reload
      end

      it 'updates the legal_aid_application.restrictions' do
        expect(legal_aid_application.restrictions).to match_array(restrictions)
      end

      xit 'redirects to check your answers' do
        # TODO: - set redirect path when known
        expect(response).to redirect_to(:some_path)
      end

      it 'displays a holding page' do
        # TODO: - replace with 'redirects to check your answers'
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Holding page')
      end
    end

    context 'on error' do
      let(:restriction_ids) { %i[foo bar] }

      # As I can not think of a "normal" behaviour that can cause an error.
      # Error handling falls back to standard error handling.
      it 'raises error' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end