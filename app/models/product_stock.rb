class ProductStock < ApplicationRecord
  belongs_to :product
  belongs_to :warehouse

  validates :product, presence: true, unless: -> { new_record? }
  validates :warehouse_id, presence: true
  validates :quantity, presence: true, numericality: true
end
