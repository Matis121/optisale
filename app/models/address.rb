class Address < ApplicationRecord
  belongs_to :order

  enum :kind, { delivery: 0, invoice: 1 }

  validates :kind, presence: true
  validates :fullname, length: { maximum: 100 }
  validates :company_name, length: { maximum: 100 }
  validates :street, length: { maximum: 100 }
  validates :postcode, length: { maximum: 10 }
  validates :city, length: { maximum: 50 }
  validates :country, length: { maximum: 50 }
  validates :nip, length: { maximum: 100 }

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[fullname company_name street postcode city country country_code phone kind nip]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[order]
  end
end
