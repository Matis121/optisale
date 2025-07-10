class PriceGroup < ApplicationRecord
  belongs_to :catalog
  has_many :product_prices, dependent: :destroy

  validates :name, presence: true
  validates :catalog_id, presence: true
end
