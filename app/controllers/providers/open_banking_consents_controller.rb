module Providers
  class OpenBankingConsentsController < ProviderBaseController
    def show
      legal_aid_application.reset_from_use_ccms! if legal_aid_application.use_ccms?
      @form = LegalAidApplications::OpenBankingConsentForm.new(model: legal_aid_application)
    end

    def update
      @form = LegalAidApplications::OpenBankingConsentForm.new(form_params)
      render :show unless save_continue_or_draft(@form)
    end

    private

    def form_params
      merge_with_model(legal_aid_application) do
        return {} unless params[:legal_aid_application]

        params.require(:legal_aid_application).permit(:citizen_uses_online_banking, :provider_received_citizen_consent, :none_selected)
      end
    end
  end
end
