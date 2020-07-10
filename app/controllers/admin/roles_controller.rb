module Admin
  class RolesController < ApplicationController
    before_action :authenticate_admin_user!
    layout 'admin'.freeze

    def index
      ap 11111111
      provider_firms
    end

    private

    def provider_firms
      ap 22222222
      ap "this is A TEST ***************************************"
      @provider_firms ||= Firm.all
    end
  end
end

