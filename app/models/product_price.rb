class ProductPrice < ApplicationRecord
  belongs_to :product
  belongs_to :price_group

  validates :product_id, presence: true
  validates :price_group_id, presence: true
  validates :nett_price, presence: true, numericality: true
  validates :gross_price, presence: true, numericality: true
  validates :currency, presence: true
end
