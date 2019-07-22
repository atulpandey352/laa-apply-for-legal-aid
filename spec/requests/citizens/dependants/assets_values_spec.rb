require 'rails_helper'

RSpec.describe Citizens::Dependants::AssetsValuesController, type: :request do
  let(:legal_aid_application) { create :legal_aid_application, :with_applicant }
  let(:dependant) { create :dependant, legal_aid_application: legal_aid_application }

  before do
    get citizens_legal_aid_application_path(legal_aid_application.generate_secure_id)
    subject
  end

  describe 'GET /citizens/dependants/:dependant_id/assets_values' do
    subject { get citizens_dependant_assets_value_path(dependant) }

    it 'returns http success' do
      expect(response).to have_http_status(:ok)
    end

    it "contains dependant's informations" do
      expect(unescaped_response_body).to include(dependant.name)
    end
  end

  describe 'PATCH /citizens/dependants/:id/assets_values' do
    let(:has_assets_more_than_threshold) { true }
    let(:assets_value) { 10_000 }
    let(:params) do
      {
        dependant: {
          has_assets_more_than_threshold: has_assets_more_than_threshold.to_s,
          assets_value: assets_value.to_s
        }
      }
    end

    subject { patch citizens_dependant_assets_value_path(dependant), params: params }

    it 'updates the dependant' do
      dependant.reload
      expect(dependant.has_assets_more_than_threshold).to eq(has_assets_more_than_threshold)
      expect(dependant.assets_value).to eq(assets_value)
    end

    it 'redirects to the page asking if you have other dependant' do
      expect(response).to redirect_to(citizens_has_other_dependant_path)
    end

    context 'invalid params' do
      context 'params are missing' do
        let(:has_assets_more_than_threshold) { '' }
        let(:assets_value) { '' }

        it 'shows errors' do
          expect(unescaped_response_body).to include(I18n.t('activemodel.errors.models.dependant.attributes.has_assets_more_than_threshold.blank_message', name: dependant.name))
        end
      end

      context 'assets_value is missing' do
        let(:assets_value) { '' }

        it 'shows errors' do
          expect(unescaped_response_body).to include(I18n.t('activemodel.errors.models.dependant.attributes.assets_value.blank'))
        end
      end

      context 'invalid value' do
        let(:assets_value) { 'hello' }

        it 'shows errors' do
          expect(unescaped_response_body).to include(I18n.t('activemodel.errors.models.dependant.attributes.assets_value.not_a_number'))
        end
      end

      context 'too many decimals' do
        let(:assets_value) { 10_000.123 }

        it 'shows errors' do
          expect(unescaped_response_body).to include(I18n.t('activemodel.errors.models.dependant.attributes.assets_value.too_many_decimals'))
        end
      end

      context 'value less than threshold' do
        let(:assets_value) { 123 }

        it 'shows errors' do
          expect(unescaped_response_body).to include(I18n.t('activemodel.errors.models.dependant.attributes.assets_value.less_than_threshold', name: dependant.name))
        end
      end
    end
  end
end