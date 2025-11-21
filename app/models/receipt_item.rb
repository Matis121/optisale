class ReceiptItem < ApplicationRecord
  belongs_to :receipt

  validates :name, presence: true, length: { maximum: 200 }
  validates :sku, length: { maximum: 50 }
  validates :ean, length: { maximum: 32 }
  validates :price_brutto, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :tax_rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
