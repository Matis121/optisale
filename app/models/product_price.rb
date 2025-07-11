class ProductPrice < ApplicationRecord
  belongs_to :product
  belongs_to :price_group

  validates :product, presence: true, unless: -> { new_record? }
  validates :price_group_id, presence: true
  validates :nett_price, presence: true, numericality: true
  validates :gross_price, presence: true, numericality: true
  validates :currency, presence: true
end
