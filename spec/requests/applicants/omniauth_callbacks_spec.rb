require 'rails_helper'

RSpec.describe 'applicants omniauth call back', type: :request do
  around(:example) do |example|
    OmniAuth.config.test_mode = true
    example.run
    OmniAuth.config.mock_auth[:true_layer] = nil
    OmniAuth.config.test_mode = false
  end

  let(:token) { SecureRandom.uuid }
  let(:applicant) { create :applicant }
  let(:bank_provider) { applicant.bank_providers.find_by(token: token) }

  before do
    sign_in applicant if applicant
    OmniAuth.config.add_mock(
      :true_layer,
      credentials: { token: token }
    )

    stub_true_layer
  end

  describe 'GET /applicants/auth/true_layer/callback' do
    subject { get applicant_true_layer_omniauth_callback_path }

    it 'should redirect to next page' do
      expect(subject).to redirect_to(citizens_accounts_path)
    end

    it 'should import bank provider' do
      expect { subject }.to change { applicant.bank_providers.count }.by(1)
      expect(bank_provider).not_to be_nil
    end

    it 'should import bank data' do
    end

    context 'without applicant' do
      let(:applicant) { nil }

      it 'should redirect to root' do
        expect(subject).to redirect_to(citizens_consent_path)
      end
    end

    context 'bank import is failing' do
      let(:api_error) do
        {
          error_description: 'Feature not supported by the provider',
          error: :endpoint_not_supported,
          error_details: { foo: :bar }
        }
      end

      before do
        endpoint = TrueLayer::ApiClient::TRUE_LAYER_URL + '/data/v1/accounts'
        stub_request(:get, endpoint).to_return(body: api_error.to_json, status: 501)
      end

      it 'shows the error' do
        subject
        expect(response.request.flash[:error]).to include(api_error[:error_description])
      end
    end

    context 'on authentication failure' do
      before do
        OmniAuth.config.mock_auth[:true_layer] = :invalid_credentials
      end

      it 'should redirect to root' do
        # Faraday defined within OAuth2::Client outputs to console on error
        # which then outputs into the standard rspec progress sequence rather
        # than to logs. Mocking `logger.add` silences that output for this spec
        allow_any_instance_of(Logger).to receive(:add)
        subject
        follow_redirect!
        expect(request.env['REQUEST_URI']).to eq(citizens_consent_path)
      end
    end
  end
end
