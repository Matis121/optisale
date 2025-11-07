class StockManagementService
  attr_reader :errors

  def initialize
    @errors = []
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
          product.update_stock!(warehouse, new_quantity, user,
                               movement_type: movement_type)
          results << { product: product, success: true }
        rescue => e
          results << { product: product, success: false, error: e.message }
          @errors << "#{product.name}: #{e.message}"
        end
      end

      # Rollback if there are errors (optional - depends on requirements)
      # raise ActiveRecord::Rollback if @errors.any?
    end

    results
  end

  # Check product availability for order
  def check_availability_for_order(order_products, warehouse)
    availability_report = []

    order_products.each do |order_product|
      product = order_product.product
      required_quantity = order_product.quantity
      available_quantity = product.stock_in_warehouse(warehouse)

      availability_report << {
        product: product,
        required: required_quantity,
        available: available_quantity,
        sufficient: available_quantity >= required_quantity,
        shortage: [ 0, required_quantity - available_quantity ].max
      }
    end

    availability_report
  end

  # Stock reservation (soft reservation)
  def reserve_stock_for_order(order, warehouse = nil)
    warehouse ||= order.account.warehouses.find_by(default: true)
    return false unless warehouse

    availability = check_availability_for_order(order.order_products, warehouse)

    # Check if all products are available
    insufficient_products = availability.select { |item| !item[:sufficient] }

    if insufficient_products.any?
      @errors = insufficient_products.map do |item|
        "#{item[:product].name}: niewystarczający stan (dostępne: #{item[:available]}, wymagane: #{item[:required]})"
      end
      return false
    end

    true
  end

  # Calculate warehouse stock values
  private
end
