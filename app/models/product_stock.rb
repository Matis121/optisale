class ProductStock < ApplicationRecord
  belongs_to :product
  belongs_to :warehouse

  validates :product, presence: true, unless: -> { new_record? }
  validates :warehouse_id, presence: true
  validates :quantity, presence: true, numericality: true

  after_create :create_initial_stock_movement

  private

  def create_initial_stock_movement
    product.stock_movements.create!(
      account: warehouse.account,
      warehouse: warehouse,
      user: warehouse.account.users.first || warehouse.account.owner,
      movement_type: "product_creation",
      quantity: quantity,
      stock_before: 0,
      stock_after: quantity,
      occurred_at: Time.current
    )
  end
end
