class Integration < ApplicationRecord
  enum :integration_type, { marketplace: "marketplace", invoicing: "invoicing", shipping: "shipping" }

  enum :key, { fakturownia: "fakturownia" }

  validates :name, presence: true
  validates :key, presence: true
  validates :integration_type, presence: true
  validates :multiple_allowed, inclusion: { in: [ true, false ] }
  validates :enabled, inclusion: { in: [ true, false ] }
  validates :beta, inclusion: { in: [ true, false ] }

  # TODO: In production, consider implementing proper encryption (Rails credentials or external vault)
end
