class Order < ApplicationRecord
  belongs_to :user
  belongs_to :order_status, foreign_key: :status_id
  has_many :order_products
  has_many :addresses, dependent: :destroy

  after_initialize :build_blank_addresses, if: :new_record?

  def build_blank_addresses
    addresses.build(kind: 0)
    addresses.build(kind: 1)
  end
end
