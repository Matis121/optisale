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

  # Method to update stock with logging
  def update_stock!(warehouse, new_quantity, user, movement_type: "manual_adjustment", reference: nil)
    product_stock = product_stocks.find_or_initialize_by(warehouse: warehouse)
    old_quantity = product_stock.quantity || 0
    quantity_change = new_quantity - old_quantity

    return true if quantity_change == 0 # Brak zmian

    # Validation that stock won't go negative
    if new_quantity < 0
      raise ArgumentError, "Stan magazynowy nie może być ujemny"
    end

    ActiveRecord::Base.transaction do
      # Aktualizuj stan
      product_stock.quantity = new_quantity
      product_stock.save!

      # Zapisz ruch magazynowy
      stock_movements.create!(
        account: warehouse.account,
        warehouse: warehouse,
        user: user,
        movement_type: movement_type,
        quantity: quantity_change,
        stock_before: old_quantity,
        stock_after: new_quantity,
        reference: reference,
        occurred_at: Time.current
      )
    end

    true
  end

  # Method to reduce stock (e.g., when placing order)
  def reduce_stock!(warehouse, quantity_to_reduce, user, reference: nil)
    product_stock = product_stocks.find_by(warehouse: warehouse)
    current_quantity = product_stock&.quantity || 0

    if current_quantity < quantity_to_reduce
      raise ArgumentError, "Niewystarczający stan magazynowy. Dostępne: #{current_quantity}, wymagane: #{quantity_to_reduce}"
    end

    new_quantity = current_quantity - quantity_to_reduce
    update_stock!(warehouse, new_quantity, user,
                  movement_type: "order_placement",
                  reference: reference)
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
