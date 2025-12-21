class OrderProduct < ApplicationRecord
  belongs_to :order
  belongs_to :product, optional: true

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :order_id, presence: true
  validate :check_stock_availability, if: :product_present_and_quantity_changed?

  before_save :set_product_details, if: :product_id_changed?

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

  # NEW METHODS - delegates to StockManagementService:
  def reduce_stock_on_create
    return unless product

    default_warehouse = order.account.warehouses.find_by(default: true)
    return unless default_warehouse

    current_user = order.account.users.first || order.account.owner
    return unless current_user

    # Delegates to StockManagementService
    stock_service = StockManagementService.new
    stock_service.adjust_stock_for_order(
      product: product,
      warehouse: default_warehouse,
      quantity: quantity,
      user: current_user,
      order: order,
      action: "reduce"
    )
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

    # Delegates to StockManagementService
    stock_service = StockManagementService.new
    stock_service.adjust_stock_for_order(
      product: product,
      warehouse: default_warehouse,
      quantity: quantity_difference,
      user: current_user,
      order: order,
      action: "adjust"
    )
  end

  def restore_stock_on_destroy
    return unless product

    default_warehouse = order.account.warehouses.find_by(default: true)
    return unless default_warehouse

    current_user = order.account.users.first || order.account.owner
    return unless current_user

    # Delegates to StockManagementService
    stock_service = StockManagementService.new
    stock_service.adjust_stock_for_order(
      product: product,
      warehouse: default_warehouse,
      quantity: -quantity, # negative value = restore
      user: current_user,
      order: order,
      action: "restore"
    )
  end
end
