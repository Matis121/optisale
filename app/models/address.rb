class Address < ApplicationRecord
  belongs_to :order

  enum :kind, { delivery: 0, invoice: 1 }

  validates :kind, presence: true

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[fullname company_name street postcode city country country_code phone kind]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[order]
  end
end
