class Order < ApplicationRecord
  belongs_to :user
  belongs_to :order_status, foreign_key: :status_id
  belongs_to :customer
  has_many :order_products, dependent: :destroy
  has_many :addresses, dependent: :destroy
  has_one :customer_pickup_point, dependent: :destroy

  after_initialize :build_blank_addresses, if: :new_record?

  # Ransack configuration - definiowanie jakie pola mogą być przeszukiwane
  def self.ransackable_attributes(auth_object = nil)
    %w[id created_at updated_at status_id payment_method shipping_method amount_paid shipping_cost]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[order_status customer addresses order_products]
  end

  def self.ransackable_scopes(auth_object = nil)
    %w[total_amount_gteq total_amount_lteq]
  end

  # Scopes for total amount filtering
  scope :total_amount_gteq, ->(amount) {
    return all if amount.blank?
    where(id: joins(:order_products)
      .group("orders.id")
      .having("SUM(order_products.quantity * order_products.gross_price) + COALESCE(orders.shipping_cost, 0) >= ?", amount.to_f)
      .select("orders.id"))
  }

  scope :total_amount_lteq, ->(amount) {
    return all if amount.blank?
    where(id: joins(:order_products)
      .group("orders.id")
      .having("SUM(order_products.quantity * order_products.gross_price) + COALESCE(orders.shipping_cost, 0) <= ?", amount.to_f)
      .select("orders.id"))
  }

  # Custom ransacker for total amount
  ransacker :total_amount do |parent|
    Arel.sql("(SELECT SUM(order_products.quantity * order_products.gross_price) + COALESCE(orders.shipping_cost, 0) FROM order_products WHERE order_products.order_id = orders.id)")
  end



  def build_blank_addresses
    addresses.build(kind: :delivery)
    addresses.build(kind: :invoice)
    build_customer_pickup_point
    build_customer
  end

  def total_price
    order_products.sum("quantity * gross_price") + shipping_cost.to_f
  end
end
