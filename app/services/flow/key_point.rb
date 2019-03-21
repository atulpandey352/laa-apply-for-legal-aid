module Flow
  class KeyPoint
    KEY_POINTS = {
      citizens: {},
      providers: {
        start_after_applicant_completes_means: :check_merits_answers,
        start_income_update: :capital_introductions,
        start_outgoing_update: :foo
      }
    }.freeze

    def self.step_for(journey:, key_point:)
      new(journey, key_point).step
    end

    def self.path_for(journey:, key_point:, legal_aid_application:)
      new(journey, key_point).path(legal_aid_application)
    end

    attr_reader :journey, :key_point

    def initialize(journey, key_point)
      @journey = journey
      @key_point = key_point
    end

    def step
      KEY_POINTS.dig journey, key_point
    end

    def path(legal_aid_application)
      flow(legal_aid_application).current_path
    end

    private

    def flow((legal_aid_application))
      Flow::BaseFlowService.flow_service_for(
        journey,
        legal_aid_application: legal_aid_application,
        current_step: step
      )
    end

  end
end
