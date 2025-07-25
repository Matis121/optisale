class OrderProduct < ApplicationRecord
  belongs_to :order
  belongs_to :product, optional: true

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :order_id, presence: true
end
