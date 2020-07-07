require 'rails_helper'

module CFE
  RSpec.describe SubmissionManager do
    let(:vehicle) { build :vehicle, :populated }

    let(:submission_manager) { described_class.new(application.id) }
    let(:submission) { submission_manager.submission }
    let(:call_result) { true }

    describe '.call', vcr: { record: :new_episodes } do
      let(:application) { create :legal_aid_application, :with_everything, :with_positive_benefit_check_result, :applicant_entering_means, vehicle: vehicle }
      let(:staging_host) { 'https://check-financial-eligibility-staging.apps.live-1.cloud-platform.service.justice.gov.uk' }
      let(:last_submission_history) { SubmissionHistory.order(created_at: :asc).last }
      before do
        allow(Rails.configuration.x).to receive(:check_financial_eligibility_host).and_return(staging_host)
      end

      it 'completes process' do
        described_class.call(application.id)
        expect(last_submission_history.http_response_status).to eq(200), last_submission_history.inspect
      end
    end

    describe '#call' do
      context 'new_student_loan setting is false' do
        before do
          Setting.setting.update!(use_new_student_loan: false)
          allow(CreateAssessmentService).to receive(:call).and_return(true)
          allow(CreateApplicantService).to receive(:call).and_return(true)
          allow(CreateCapitalsService).to receive(:call).and_return(true)
          allow(CreatePropertiesService).to receive(:call).and_return(true)
          allow(CreateVehiclesService).to receive(:call).and_return(true)
          allow(CreateStateBenefitsService).to receive(:call).and_return(true)
          allow(CreateDependantsService).to receive(:call).and_return(true)
          allow(CreateOtherIncomeService).to receive(:call).and_return(true)
          allow(ObtainAssessmentResultService).to receive(:call).and_return(true)
        end

        context 'passported application' do
          let(:application) { create :legal_aid_application, :with_everything, :with_positive_benefit_check_result, :applicant_entering_means, vehicle: vehicle }

          it 'creates a submission record' do
            expect { submission_manager.call }.to change { Submission.count }.by(1)
          end

          it 'calls all the services it manages' do
            expect(CreateAssessmentService).to receive(:call).and_return(true)
            expect(CreateApplicantService).to receive(:call).and_return(true)
            expect(CreateCapitalsService).to receive(:call).and_return(true)
            expect(CreatePropertiesService).to receive(:call).and_return(true)
            expect(CreateVehiclesService).to receive(:call).and_return(true)
            expect(ObtainAssessmentResultService).to receive(:call).and_return(true)
            submission_manager.call
          end

          it 'does not call the services only required for non-passported applications' do
            expect(CreateStateBenefitsService).not_to receive(:call)
            expect(CreateDependantsService).not_to receive(:call)
            expect(CreateOtherIncomeService).not_to receive(:call)
            expect(CreateIrregularIncomesService).not_to receive(:call)
            submission_manager.call
          end

          context 'on submission error' do
            let(:message) { Faker::Lorem.sentence }
            before do
              allow(CreateAssessmentService).to receive(:call).and_raise(SubmissionError, message)
            end

            it 'records error in submission' do
              submission_manager.call
              expect(submission.error_message).to eq(message)
              expect(submission).to be_failed
            end

            it 'captures error' do
              expect(Raven).to receive(:capture_exception).with(message_contains(message))
              submission_manager.call
            end

            context 'does not change state if already :failed' do
              before do
                allow(CreateAssessmentService).to receive(:call).and_raise(SubmissionError, message)
                submission.fail!
              end
              it 'records error in submission' do
                submission_manager.call
                expect(submission.error_message).to eq(message)
                expect(submission).to be_failed
              end
            end
          end
        end

        context 'non-passported application' do
          let(:application) { create :legal_aid_application, :with_everything, :with_negative_benefit_check_result, :applicant_entering_means, vehicle: vehicle }

          context 'Setting set not to use new student loan' do
            it 'calls all the services it manages but does not call CreateIrregularIncomesService' do
              expect(CreateAssessmentService).to receive(:call).and_return(true)
              expect(CreateApplicantService).to receive(:call).and_return(true)
              expect(CreateCapitalsService).to receive(:call).and_return(true)
              expect(CreatePropertiesService).to receive(:call).and_return(true)
              expect(CreateVehiclesService).to receive(:call).and_return(true)
              expect(ObtainAssessmentResultService).to receive(:call).and_return(true)
              expect(CreateStateBenefitsService).to receive(:call).and_return(true)
              expect(CreateDependantsService).to receive(:call).and_return(true)
              expect(CreateOutgoingsService).to receive(:call).and_return(true)
              expect(CreateOtherIncomeService).to receive(:call).and_return(true)

              expect(CreateIrregularIncomesService).not_to receive(:call)

              submission_manager.call
            end
          end

          describe '#submission' do
            it 'associates the application with the submission' do
              expect(submission.legal_aid_application_id).to eq application.id
            end
          end

          context 'use new student loan is set to true' do
            it 'calls the CreateIrregularIncomesService along with all the others' do
              Setting.setting.update(use_new_student_loan: true)
              expect(CreateAssessmentService).to receive(:call).and_return(true)
              expect(CreateApplicantService).to receive(:call).and_return(true)
              expect(CreateCapitalsService).to receive(:call).and_return(true)
              expect(CreatePropertiesService).to receive(:call).and_return(true)
              expect(CreateVehiclesService).to receive(:call).and_return(true)
              expect(ObtainAssessmentResultService).to receive(:call).and_return(true)
              expect(CreateStateBenefitsService).to receive(:call).and_return(true)
              expect(CreateDependantsService).to receive(:call).and_return(true)
              expect(CreateOutgoingsService).to receive(:call).and_return(true)
              expect(CreateOtherIncomeService).to receive(:call).and_return(true)
              expect(CreateIrregularIncomesService).to receive(:call).and_return(true)
              submission_manager.call
            end
          end
        end
      end
    end
  end
end
