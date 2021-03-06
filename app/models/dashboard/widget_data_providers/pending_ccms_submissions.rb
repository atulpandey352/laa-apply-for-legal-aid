# Count of CCMS submission that have not yet completed
module Dashboard
  module WidgetDataProviders
    class PendingCcmsSubmissions
      def self.dataset_definition
        {
          fields: [
            Geckoboard::NumberField.new(:number, name: 'Pending CCMS Submissions')
          ]
        }
      end

      def self.data
        [
          {
            'number' => pending_submissions
          }
        ]
      end

      def self.handle
        'pending_ccms_submissions'
      end

      def self.pending_submissions
        CCMS::Submission.where(created_at: 6.days.ago.beginning_of_day..Time.now).where.not(aasm_state: %w[failed completed]).count
      end
    end
  end
end
