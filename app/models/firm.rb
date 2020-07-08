class Firm < ApplicationRecord
  has_many :offices
  has_many :providers
  has_many :legal_aid_applications, through: :providers

  has_many :actor_permissions, as: :permittable
  has_many :permissions, through: :actor_permissions

  after_create do
    ActiveSupport::Notifications.instrument 'dashboard.firm_created'
  end
end
