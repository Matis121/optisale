require "test_helper"

class StockManagementServiceTest < ActiveSupport::TestCase
  def setup
    @service = StockManagementService.new
    @user = users(:one)
    @product1 = products(:one)
    @product2 = products(:two)
    @warehouse = warehouses(:one)
    @catalog = catalogs(:one)

    # Clear and create fresh product stocks for tests
    ProductStock.where(product: [ @product1, @product2 ]).destroy_all
    StockMovement.where(product: [ @product1, @product2 ]).destroy_all
    @product_stock1 = ProductStock.create!(
      product: @product1,
      warehouse: @warehouse,
      quantity: 20
    )

    @product_stock2 = ProductStock.create!(
      product: @product2,
      warehouse: @warehouse,
      quantity: 15
    )
  end

  test "should initialize with empty errors" do
    assert_empty @service.errors
  end

  # batch_update_stocks tests
  test "batch_update_stocks should update multiple products successfully" do
    stock_updates = [
      { product: @product1, warehouse: @warehouse, quantity: 25 },
      { product: @product2, warehouse: @warehouse, quantity: 30 }
    ]

    results = nil
    assert_difference "StockMovement.count", 2 do
      results = @service.batch_update_stocks(stock_updates, @user)
    end

    assert_equal 2, results.length
    results.each do |result|
      assert result[:success]
      assert_not_nil result[:product]
    end

    @product_stock1.reload
    @product_stock2.reload
    assert_equal 25, @product_stock1.quantity
    assert_equal 30, @product_stock2.quantity
  end

  test "batch_update_stocks should handle errors gracefully" do
    stock_updates = [
      { product: @product1, warehouse: @warehouse, quantity: 25 },
      { product: @product2, warehouse: @warehouse, quantity: -5 } # Invalid negative
    ]

    results = @service.batch_update_stocks(stock_updates, @user)

    assert_equal 2, results.length
    assert results[0][:success]
    assert_not results[1][:success]
    assert_not_nil results[1][:error]
    assert_not_empty @service.errors
  end

  test "batch_update_stocks should use custom movement_type" do
    stock_updates = [
      { product: @product1, warehouse: @warehouse, quantity: 25 }
    ]

    @service.batch_update_stocks(stock_updates, @user, movement_type: "stock_in")

    movement = StockMovement.last
    assert_equal "stock_in", movement.movement_type
  end

  # check_availability_for_order tests
  test "check_availability_for_order should return correct availability report" do
    order = Order.create!(user: @user, customer: customers(:one), status_id: order_statuses(:one).id)

    # Create order products (callbacks will reduce stock automatically)
    order_product1 = OrderProduct.new(
      order: order,
      product: @product1,
      quantity: 5,  # Reduced from 10 to avoid stock issues
      gross_price: 100,
      nett_price: 81.30,
      tax_rate: 23
    )
    order_product1.save!(validate: false)

    order_product2 = OrderProduct.new(
      order: order,
      product: @product2,
      quantity: 20, # More than available (15)
      gross_price: 200,
      nett_price: 162.60,
      tax_rate: 23
    )
    order_product2.save!(validate: false)

    report = @service.check_availability_for_order([ order_product1, order_product2 ], @warehouse)

    assert_equal 2, report.length

    # First product should be sufficient (available reduced by first order product)
    product1_report = report.find { |r| r[:product] == @product1 }
    assert product1_report[:sufficient]
    assert_equal 0, product1_report[:shortage]
    assert_equal 5, product1_report[:required]
    assert_equal 15, product1_report[:available]  # 20 - 5 from callback

    # Second product should be insufficient
    product2_report = report.find { |r| r[:product] == @product2 }
    assert_not product2_report[:sufficient]
    assert_equal 5, product2_report[:shortage]  # 20 - 15 available
    assert_equal 20, product2_report[:required]
    assert_equal 15, product2_report[:available]
  end

  # reserve_stock_for_order tests
  test "reserve_stock_for_order should return true when all products available" do
    order = Order.create!(user: @user, customer: customers(:one), status_id: order_statuses(:one).id)

    OrderProduct.create!(
      order: order,
      product: @product1,
      quantity: 10,
      gross_price: 100,
      nett_price: 81.30,
      tax_rate: 23
    )

    @warehouse.update!(default: true)

    result = @service.reserve_stock_for_order(order, @warehouse)
    assert result
    assert_empty @service.errors
  end

  test "reserve_stock_for_order should return false when insufficient stock" do
    order = Order.create!(user: @user, customer: customers(:one), status_id: order_statuses(:one).id)

    order_product = OrderProduct.new(
      order: order,
      product: @product1,
      quantity: 25, # More than available (20)
      gross_price: 100,
      nett_price: 81.30,
      tax_rate: 23
    )
    # Skip callbacks that would reduce stock
    order_product.save!(validate: false)

    result = @service.reserve_stock_for_order(order, @warehouse)
    assert_not result
    assert_not_empty @service.errors
    assert_includes @service.errors.first, @product1.name
    assert_includes @service.errors.first, "niewystarczający stan"
  end

  test "reserve_stock_for_order should use default warehouse when none provided" do
    order = Order.create!(user: @user, customer: customers(:one), status_id: order_statuses(:one).id)

    # Should find default warehouse and return true for empty order
    result = @service.reserve_stock_for_order(order, nil)
    assert result
  end
end
