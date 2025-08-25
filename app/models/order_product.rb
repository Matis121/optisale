class OrderProduct < ApplicationRecord
  belongs_to :order
  belongs_to :product, optional: true

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :order_id, presence: true

  before_save :set_product_details, if: :product_id_changed?

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[name sku ean quantity gross_price nett_price tax_rate]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[order product]
  end

  private

  def set_product_details
    return unless product

    self.name = product.name
    self.sku = product.sku
    self.ean = product.ean
    self.tax_rate = product.tax_rate
    set_prices
  end

  def set_prices
    default_price_group = order.user.price_groups.find_by(default: true)
    product_price = product.product_prices.find_by(price_group: default_price_group) ||
                   product.product_prices.first

    self.gross_price = product_price&.gross_price || 0
    self.nett_price = product_price&.nett_price || 0
  end
end
