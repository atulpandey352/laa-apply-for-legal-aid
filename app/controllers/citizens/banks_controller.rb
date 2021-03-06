module Citizens
  class BanksController < CitizenBaseController
    def index; end

    def create
      if params[:provider_id].present?
        session[:provider_id] = params[:provider_id]
        go_forward
      else
        @error = t('.error')
        render :index
      end
    end
  end
end
