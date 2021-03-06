module Providers
  class ConfirmOfficesController < ProviderBaseController
    legal_aid_application_not_required!
    helper_method :firm

    def show
      if firm.offices.count == 1
        current_provider.update!(selected_office: firm.offices.first)
        redirect_to providers_legal_aid_applications_path
        return
      end

      redirect_to providers_select_office_path unless current_provider.selected_office
    end

    def update
      case params[:correct]
      when 'yes'
        redirect_to providers_legal_aid_applications_path
      when 'no'
        current_provider.update!(selected_office: nil)
        redirect_to providers_select_office_path
      else
        @error = I18n.t('providers.confirm_offices.show.error')
        render :show
      end
    end

    private

    def firm
      current_provider.firm
    end
  end
end
