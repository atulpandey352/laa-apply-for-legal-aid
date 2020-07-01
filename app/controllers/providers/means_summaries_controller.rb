module Providers
  class MeansSummariesController < ProviderBaseController
    def show
      legal_aid_application.set_transaction_period
      legal_aid_application.check_non_passported_means! unless legal_aid_application.checking_non_passported_means?
    end

    def update
      unless draft_selected? || legal_aid_application.provider_checked_citizens_means_answers?
        redirect_to(problem_index_path) && return unless check_financial_eligibility

        legal_aid_application.provider_checked_citizens_means_answers!
      end
      continue_or_draft
    end

    private

    def check_financial_eligibility
      CFE::SubmissionManager.call(legal_aid_application.id)
    end
  end
end
