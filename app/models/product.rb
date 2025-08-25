class Product < ApplicationRecord
  belongs_to :catalog
  has_many :order_products
  has_many :product_stocks, dependent: :destroy
  has_many :product_prices, dependent: :destroy

  accepts_nested_attributes_for :product_stocks, :product_prices

  validates :name, presence: true
  validates :tax_rate, presence: true, numericality: true
  validates :sku, uniqueness: { scope: :catalog_id }, allow_blank: true
  validates :ean, uniqueness: { scope: :catalog_id }, allow_blank: true
  validates :catalog_id, presence: true

  def self.ransackable_attributes(auth_object = nil)
    [ "catalog_id", "created_at", "ean", "id", "name", "sku", "tax_rate", "updated_at" ]
  end
end
