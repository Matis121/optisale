class StockManagementService
  attr_reader :errors

  def initialize
    @errors = []
  end

  # Core method to update stock with logging - moved from Product model
  def update_stock!(product:, warehouse:, new_quantity:, user:, movement_type: "manual_adjustment", reference: nil)
    product_stock = product.product_stocks.find_or_initialize_by(warehouse: warehouse)
    old_quantity = product_stock.quantity || 0
    quantity_change = new_quantity - old_quantity

    return true if quantity_change == 0 # No changes

    # Validation that stock won't go negative
    raise ArgumentError, "Stan magazynowy nie może być ujemny" if new_quantity < 0

    # Use requires_new: true to avoid issues with nested transactions
    ActiveRecord::Base.transaction(requires_new: true) do
      # Update stock
      product_stock.quantity = new_quantity
      product_stock.save!

      # Log stock movement
      product.stock_movements.create!(
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

  # Method to reduce stock (e.g., when placing order) - moved from Product model
  def reduce_stock!(product:, warehouse:, quantity:, user:, reference: nil)
    product_stock = product.product_stocks.find_by(warehouse: warehouse)
    current_quantity = product_stock&.quantity || 0
    new_quantity = current_quantity - quantity

    # Better error message for insufficient stock (before generic negative check)
    if new_quantity < 0
      raise ArgumentError, "Niewystarczający stan magazynowy. Dostępne: #{current_quantity}, wymagane: #{quantity}"
    end

    update_stock!(
      product: product,
      warehouse: warehouse,
      new_quantity: new_quantity,
      user: user,
      movement_type: "order_placement",
      reference: reference
    )
  end

  # Batch update stocks for multiple products (e.g., during import)
  def batch_update_stocks(stock_updates, user, movement_type: "manual_adjustment")
    results = []

    ActiveRecord::Base.transaction do
      stock_updates.each do |update|
        product = update[:product]
        warehouse = update[:warehouse]
        new_quantity = update[:quantity]

        begin
          update_stock!(
            product: product,
            warehouse: warehouse,
            new_quantity: new_quantity,
            user: user,
            movement_type: movement_type
          )
          results << { product: product, success: true }
        rescue ArgumentError, ActiveRecord::RecordInvalid => e
          results << { product: product, success: false, error: e.message }
          @errors << "#{product.name}: #{e.message}"
        end
      end
    end

    results
  end

  # Check product availability for order
  def check_availability_for_order(order_products, warehouse)
    # Preload products and their stocks in one query to avoid N+1
    products = Product.where(id: order_products.map(&:product_id))
                      .includes(:product_stocks)
                      .index_by(&:id)

    order_products.map do |order_product|
      product = products[order_product.product_id] || order_product.product
      required_quantity = order_product.quantity
      available_quantity = product.stock_in_warehouse(warehouse)

      {
        product: product,
        required: required_quantity,
        available: available_quantity,
        sufficient: available_quantity >= required_quantity,
        shortage: [ 0, required_quantity - available_quantity ].max
      }
    end
  end

  # Stock reservation (soft reservation)
  def reserve_stock_for_order(order, warehouse = nil)
    warehouse ||= order.account.warehouses.find_by(default: true)
    return false unless warehouse

    availability = check_availability_for_order(order.order_products, warehouse)
    insufficient_products = availability.reject { |item| item[:sufficient] }

    return true if insufficient_products.empty?

    @errors = insufficient_products.map do |item|
      "#{item[:product].name}: niewystarczający stan (dostępne: #{item[:available]}, wymagane: #{item[:required]})"
    end
    false
  end

  # Dedicated method for order stock adjustments
  def adjust_stock_for_order(product:, warehouse:, quantity:, user:, order:, action:)
    case action
    when "reduce"
      reduce_stock!(product: product, warehouse: warehouse, quantity: quantity, user: user, reference: order)
    when "restore"
      restore_stock(product, warehouse, quantity.abs, user, order)
    when "adjust"
      # For adjust: positive = reduce, negative = restore
      if quantity > 0
        reduce_stock!(product: product, warehouse: warehouse, quantity: quantity, user: user, reference: order)
      else
        restore_stock(product, warehouse, quantity.abs, user, order)
      end
    end
    { success: true }
  rescue ArgumentError => e
    @errors << e.message
    { success: false, error: e.message }
  end

# Update product with stock changes - centralized logic
def update_product_with_stocks(product:, params:, user:)
  stock_changes = []
  other_stock_updates = {}
  new_stocks = []

  # Preload product_stocks once to avoid N+1
  product_stocks_by_id = product.product_stocks.includes(:warehouse).index_by(&:id)

  # Collect stock changes and other attributes in one pass
  if params[:product_stocks_attributes]
    params[:product_stocks_attributes].each do |_, stock_attrs|
      if stock_attrs[:id].present?
        # UPDATE existing stock
        existing_stock = product_stocks_by_id[stock_attrs[:id].to_i]
        next unless existing_stock

        new_quantity = stock_attrs[:quantity].to_i
        old_quantity = existing_stock.quantity

        # Collect quantity changes for stock movements
        if old_quantity != new_quantity
          stock_changes << {
            product: product,
            warehouse: existing_stock.warehouse,
            quantity: new_quantity,
            old_quantity: old_quantity
          }
        end

        # Collect other attribute changes
        other_attrs = stock_attrs.except(:quantity)
        other_stock_updates[existing_stock] = other_attrs if other_attrs.present?
      elsif stock_attrs[:warehouse_id].present?
        # CREATE new stock for new warehouse
        new_stocks << stock_attrs
      end
    end
  end

  # Remove stock attributes - will be handled separately
  product_params = params.except(:product_stocks_attributes)

  ActiveRecord::Base.transaction do
    # Update product (without stocks)
    product.update!(product_params)

    # Handle stock quantity changes through stock movements
    batch_update_stocks(stock_changes, user, movement_type: "manual_adjustment") if stock_changes.any?

    # Update remaining stock attributes (without quantity - already handled)
    other_stock_updates.each do |stock, attrs|
      stock.update!(attrs)
    end

    # CREATE new stocks for new warehouses
    new_stocks.each do |stock_attrs|
      warehouse = Warehouse.find(stock_attrs[:warehouse_id])
      new_quantity = stock_attrs[:quantity].to_i

      if new_quantity > 0
        update_stock!(
          product: product,
          warehouse: warehouse,
          new_quantity: new_quantity,
          user: user,
          movement_type: "stock_in"
        )
      end
    end
  end

  { success: true, product: product }
rescue ActiveRecord::RecordInvalid, ArgumentError => e
  @errors << e.message
  { success: false, error: e.message }
end

  private

  def restore_stock(product, warehouse, quantity, user, order)
    current_stock = product.stock_in_warehouse(warehouse)
    new_stock = current_stock + quantity
    update_stock!(
      product: product,
      warehouse: warehouse,
      new_quantity: new_stock,
      user: user,
      movement_type: "return",
      reference: order
    )
  end
end
