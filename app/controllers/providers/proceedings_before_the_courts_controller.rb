module Providers
  class ProceedingsBeforeTheCourtsController < BaseController
    include ApplicationDependable
    include Flowable
    before_action :authorize_legal_aid_application

    def show
      @form = MeritsAssessments::ProceedingsBeforeTheCourtForm.new(model: merits_assessment)
    end

    def update
      @form = MeritsAssessments::ProceedingsBeforeTheCourtForm.new(proceedings_before_the_court_params.merge(model: merits_assessment))

      if @form.save
        go_forward
      else
        render :show
      end
    end

    private

    def proceedings_before_the_court_params
      params.require(:merits_assessment).permit(:proceedings_before_the_court, :details_of_proceedings_before_the_court)
    end

    def merits_assessment
      @merits_assessment ||= legal_aid_application.merits_assessment || legal_aid_application.build_merits_assessment
    end

    def authorize_legal_aid_application
      authorize legal_aid_application
    end
  end
end