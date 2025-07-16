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

  filterrific(
    available_filters: [
      :with_tax_rate,
      :with_ean,
      :with_sku,
      :with_name,
    ]
  )

  scope :with_tax_rate, ->(tax_rate) { where(tax_rate: tax_rate) }
  scope :with_ean, ->(ean) { where('ean = ?', ean) }
  scope :with_sku, ->(sku) { where('sku = ?', sku) }
  scope :with_name, ->(name) { where('name ILIKE ?', "%#{name}%") }
end
