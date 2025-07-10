class ProductStock < ApplicationRecord
  belongs_to :product
  belongs_to :warehouse

  validates :product_id, presence: true
  validates :warehouse_id, presence: true
  validates :quantity, presence: true, numericality: true
end
