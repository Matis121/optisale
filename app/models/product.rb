class Product < ApplicationRecord
  belongs_to :catalog
  has_many :order_products
  has_many :product_stocks, dependent: :destroy
  has_many :product_prices, dependent: :destroy
  has_many :stock_movements, dependent: :destroy

  accepts_nested_attributes_for :product_stocks, :product_prices

  validates :name, presence: true
  validates :tax_rate, presence: true, numericality: true
  validates :sku, uniqueness: { scope: :catalog_id }, allow_blank: true
  validates :ean, uniqueness: { scope: :catalog_id }, allow_blank: true
  validates :catalog_id, presence: true

  def self.ransackable_attributes(auth_object = nil)
    [ "catalog_id", "created_at", "ean", "id", "name", "sku", "tax_rate", "updated_at" ]
  end

  # Method to check warehouse availability
  def available_in_warehouse?(warehouse, required_quantity)
    stock = product_stocks.find_by(warehouse: warehouse)
    (stock&.quantity || 0) >= required_quantity
  end

  # Total stock in all warehouses
  def total_stock
    product_stocks.sum(:quantity)
  end

  # Stan w konkretnym magazynie
  def stock_in_warehouse(warehouse)
    product_stocks.find_by(warehouse: warehouse)&.quantity || 0
  end
end
