require 'rails_helper'

RSpec.describe DashboardEventHandler do
  context 'unrecognised dashboard event' do
    it 'raises' do
      expect {
        ActiveSupport::Notifications.instrument 'dashboard.zzzzz'
      }.to raise_error DashboardEventHandler::UnrecognisedEventError, 'Unrecognised event: dashboard.zzzzz'
    end
  end

  context 'unrecognized non-dashboard event' do
    it 'does not raise' do
      expect {
        ActiveSupport::Notifications.instrument 'other_category.zzzzz'
      }.not_to raise_error
    end
  end

  context 'application created' do
    before do
      allow_any_instance_of(DashboardEventHandler).to receive(:provider_created)
      allow_any_instance_of(DashboardEventHandler).to receive(:firm_created)
    end
    it 'fires an application_created event' do
      expect_any_instance_of(DashboardEventHandler).to receive(:application_created).and_call_original
      expect(Dashboard::UpdaterJob).to receive(:perform_later).with('Applications').at_least(1).times

      create :legal_aid_application
    end
  end

  context 'provider_created' do
    before do
      allow_any_instance_of(DashboardEventHandler).to receive(:firm_created)
    end
    it 'fires a provider_created event' do
      expect_any_instance_of(DashboardEventHandler).to receive(:provider_created).and_call_original
      expect(Dashboard::UpdaterJob).to receive(:perform_later).with('DailyNewProviders')

      create :provider
    end
  end

  context 'firm_created' do
    it 'fires a NumberProviderFirms job' do
      expect(Dashboard::UpdaterJob).to receive(:perform_later).with('NumberProviderFirms')
      create :firm
    end
  end

  context 'ccms_submission_saved' do
    subject { create :ccms_submission, aasm_state: state }

    before { ActiveJob::Base.queue_adapter = :test }

    after { ActiveJob::Base.queue_adapter = :sidekiq }

    context 'saved with state failed' do
      let(:state) { 'failed' }

      it 'fires the Applications job' do
        expect { subject }.to have_enqueued_job(Dashboard::UpdaterJob).with('Applications').at_least(1).times
      end

      it 'does not fire a PendingCcmsSubmissions job' do
        expect { subject }.to_not have_enqueued_job(Dashboard::UpdaterJob).with('PendingCcmsSubmissions')
      end
    end

    context 'saved with_state completed' do
      let(:state) { 'completed' }

      it 'does not fire the Applications job' do
        expect { subject }.to have_enqueued_job(Dashboard::UpdaterJob).with('Applications').at_least(1).times
      end

      it 'does not fire a PendingCcmsSubmissions job' do
        expect { subject }.to_not have_enqueued_job(Dashboard::UpdaterJob).with('PendingCcmsSubmissions')
      end
    end
  end

  context 'feedback_created' do
    it 'fires both Average Feedback jobs' do
      expect(Dashboard::UpdaterJob).to receive(:perform_later).with('FeedbackScores')
      create :feedback
    end
  end

  context 'delegated_functions_used' do
    subject { create :legal_aid_application, :with_delegated_functions }

    before { ActiveJob::Base.queue_adapter = :test }

    after { ActiveJob::Base.queue_adapter = :sidekiq }

    it 'fires the Applications job' do
      expect { subject }.to have_enqueued_job(Dashboard::UpdaterJob).with('Applications').at_least(1).times
    end
  end

  context 'merits_assessment_submitted' do
    before do
      allow_any_instance_of(DashboardEventHandler).to receive(:firm_created)
      allow_any_instance_of(DashboardEventHandler).to receive(:provider_created)
      allow_any_instance_of(DashboardEventHandler).to receive(:application_created)
    end
    it 'fires the submitted applications job' do
      expect(Dashboard::UpdaterJob).to receive(:perform_later).with('Applications').at_least(1).times
      merits_assessment = create :merits_assessment
      merits_assessment.submit!
    end
  end
end
