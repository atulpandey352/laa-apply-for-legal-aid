class SavingsAmount < ApplicationRecord
  include Capital

  belongs_to :legal_aid_application

  def values?
    total = 0
    all_attributes.each { |attr| total += __send__(attr) unless __send__(attr).nil? }
    total != 0
  end

  private

  def all_attributes
    %i[
      offline_current_accounts
      offline_savings_accounts
      cash
      other_person_account
      national_savings
      plc_shares
      peps_unit_trusts_capital_bonds_gov_stocks
      life_assurance_endowment_policy
    ].freeze
  end
end
