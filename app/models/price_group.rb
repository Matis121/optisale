class PriceGroup < ApplicationRecord
  has_and_belongs_to_many :catalogs
  has_many :product_prices, dependent: :destroy

  validates :name, presence: true
end
