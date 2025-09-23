class StockManagementService
  attr_reader :errors

  def initialize
    @errors = []
  end

  # Batch update stanów dla wielu produktów (np. przy imporcie)
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

      # Rollback jeśli są błędy (opcjonalne - zależnie od wymagań)
      # raise ActiveRecord::Rollback if @errors.any?
    end

    results
  end

  # Sprawdzenie dostępności produktów dla zamówienia
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

  # Rezerwa stanów (soft reservation)
  def reserve_stock_for_order(order, warehouse = nil)
    warehouse ||= order.user.warehouses.find_by(default: true)
    return false unless warehouse

    availability = check_availability_for_order(order.order_products, warehouse)

    # Sprawdź czy wszystkie produkty są dostępne
    insufficient_products = availability.select { |item| !item[:sufficient] }

    if insufficient_products.any?
      @errors = insufficient_products.map do |item|
        "#{item[:product].name}: niewystarczający stan (dostępne: #{item[:available]}, wymagane: #{item[:required]})"
      end
      return false
    end

    true
  end

  # Obliczenie wartości stanów magazynowych
  private
end
