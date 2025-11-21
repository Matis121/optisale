class CustomerPickupPoint < ApplicationRecord
  belongs_to :order

  validates :name, length: { maximum: 100 }
  validates :point_id, length: { maximum: 50 }
  validates :address, length: { maximum: 100 }
  validates :city, length: { maximum: 50 }
  validates :postcode, length: { maximum: 10 }
  validates :country, length: { maximum: 50 }
end
