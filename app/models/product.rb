class Product < ApplicationRecord
  belongs_to :catalog
  has_many :order_products
  has_many :product_stocks, dependent: :destroy
  has_many :product_prices, dependent: :destroy

  validates :name, presence: true
  validates :tax_rate, presence: true, numericality: true
  validates :sku, presence: true, uniqueness: { scope: :catalog_id }
  validates :ean, presence: true, uniqueness: { scope: :catalog_id }
  validates :catalog_id, presence: true
end
