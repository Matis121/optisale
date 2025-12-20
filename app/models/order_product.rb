class OrderProduct < ApplicationRecord
  belongs_to :order
  belongs_to :product, optional: true

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :order_id, presence: true
  validate :check_stock_availability, if: :product_present_and_quantity_changed?

  before_save :set_product_details, if: :product_id_changed?

  # DODAJ te hooki:
  after_create :reduce_stock_on_create
  after_update :adjust_stock_on_update, if: :saved_change_to_quantity?
  before_destroy :restore_stock_on_destroy

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[name sku ean quantity gross_price tax_rate]
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
    default_price_group = order.account.price_groups.find_by(default: true)
    product_price = product.product_prices.find_by(price_group: default_price_group) ||
                   product.product_prices.first

    self.gross_price = product_price&.gross_price || 0
  end

  def product_present_and_quantity_changed?
    product.present? && (quantity_changed? || product_id_changed?)
  end

  def check_stock_availability
    return unless order&.persisted?
    return unless product

    default_warehouse = order.account.warehouses.find_by(default: true)
    return unless default_warehouse

    available_quantity = product.stock_in_warehouse(default_warehouse)

    if quantity > available_quantity
      errors.add(:quantity, "przekracza dostępny stan magazynowy (dostępne: #{available_quantity})")
    end
  end

  # NOWE METODY:
  def reduce_stock_on_create
    return unless product

    default_warehouse = order.account.warehouses.find_by(default: true)
    return unless default_warehouse

    current_user = order.account.users.first || order.account.owner
    return unless current_user

    begin
      product.reduce_stock!(
        default_warehouse,
        quantity,
        current_user,
        reference: order
      )
    rescue ArgumentError => e
    end
  end

  def adjust_stock_on_update
    return unless product

    default_warehouse = order.account.warehouses.find_by(default: true)
    return unless default_warehouse

    current_user = order.account.users.first || order.account.owner
    return unless current_user

    old_quantity = quantity_before_last_save
    quantity_difference = quantity - old_quantity

    return if quantity_difference == 0

    begin
      if quantity_difference > 0
        # Quantity increased - reduce additional stock
        product.reduce_stock!(
          default_warehouse,
          quantity_difference,
          current_user,
          reference: order
        )
      else
        # Quantity decreased - restore stock
        quantity_to_restore = -quantity_difference
        current_stock = product.stock_in_warehouse(default_warehouse)
        new_stock = current_stock + quantity_to_restore

        product.update_stock!(
          default_warehouse,
          new_stock,
          current_user,
          movement_type: "return",
          reference: order
        )
      end
    rescue ArgumentError => e
    end
  end

  def restore_stock_on_destroy
    return unless product

    default_warehouse = order.account.warehouses.find_by(default: true)
    return unless default_warehouse

    current_user = order.account.users.first || order.account.owner
    return unless current_user

    begin
      current_stock = product.stock_in_warehouse(default_warehouse)
      new_stock = current_stock + quantity

      product.update_stock!(
        default_warehouse,
        new_stock,
        current_user,
        movement_type: "return",
        reference: order
      )
    rescue ArgumentError => e
    end
  end
end
