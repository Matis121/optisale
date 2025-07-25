class Order < ApplicationRecord
  belongs_to :user
  belongs_to :order_status, foreign_key: :status_id
  belongs_to :customer
  has_many :order_products, dependent: :destroy
  has_many :addresses, dependent: :destroy
  has_one :customer_pickup_point, dependent: :destroy

  after_initialize :build_blank_addresses, if: :new_record?

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
