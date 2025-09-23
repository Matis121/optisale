require "test_helper"

class ProductTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @product = products(:one)
    @warehouse = warehouses(:one)
    @catalog = catalogs(:one)

    # Clear any existing product stock and create fresh one for tests
    ProductStock.where(product: @product, warehouse: @warehouse).destroy_all
    @product_stock = ProductStock.create!(
      product: @product,
      warehouse: @warehouse,
      quantity: 20
    )
  end

  test "update_stock! should create stock movement and update quantity" do
    initial_quantity = @product_stock.quantity
    new_quantity = 30

    assert_difference "StockMovement.count", 1 do
      @product.update_stock!(@warehouse, new_quantity, @user, movement_type: "stock_in")
    end

    @product_stock.reload
    assert_equal new_quantity, @product_stock.quantity

    movement = StockMovement.last
    assert_equal @product, movement.product
    assert_equal @warehouse, movement.warehouse
    assert_equal @user, movement.user
    assert_equal "stock_in", movement.movement_type
    assert_equal new_quantity - initial_quantity, movement.quantity
    assert_equal initial_quantity, movement.stock_before
    assert_equal new_quantity, movement.stock_after
  end

  test "update_stock! should not create movement when quantity unchanged" do
    current_quantity = @product_stock.quantity

    assert_no_difference "StockMovement.count" do
      result = @product.update_stock!(@warehouse, current_quantity, @user)
      assert result
    end
  end

  test "update_stock! should raise error for negative quantity" do
    assert_raises(ArgumentError, "Stan magazynowy nie może być ujemny") do
      @product.update_stock!(@warehouse, -5, @user)
    end
  end

  test "update_stock! should create product_stock if it doesn't exist" do
    new_warehouse = Warehouse.create!(name: "New Warehouse", user: @user)

    assert_difference [ "ProductStock.count", "StockMovement.count" ], 1 do
      @product.update_stock!(new_warehouse, 15, @user, movement_type: "stock_in")
    end

    product_stock = ProductStock.find_by(product: @product, warehouse: new_warehouse)
    assert_not_nil product_stock
    assert_equal 15, product_stock.quantity
  end

  test "reduce_stock! should reduce quantity and create movement" do
    initial_quantity = @product_stock.quantity
    quantity_to_reduce = 5

    assert_difference "StockMovement.count", 1 do
      @product.reduce_stock!(@warehouse, quantity_to_reduce, @user)
    end

    @product_stock.reload
    assert_equal initial_quantity - quantity_to_reduce, @product_stock.quantity

    movement = StockMovement.last
    assert_equal "order_placement", movement.movement_type
    assert_equal -quantity_to_reduce, movement.quantity
  end

  test "reduce_stock! should raise error when insufficient stock" do
    @product_stock.update!(quantity: 3)

    assert_raises(ArgumentError) do
      @product.reduce_stock!(@warehouse, 5, @user)
    end
  end

  test "reduce_stock! should work with reference" do
    order = Order.create!(user: @user, customer: customers(:one), status_id: order_statuses(:one).id)

    assert_difference "StockMovement.count", 1 do
      @product.reduce_stock!(@warehouse, 5, @user, reference: order)
    end

    movement = StockMovement.last
    assert_equal order, movement.reference
  end

  test "available_in_warehouse? should return correct availability" do
    @product_stock.update!(quantity: 10)

    assert @product.available_in_warehouse?(@warehouse, 5)
    assert @product.available_in_warehouse?(@warehouse, 10)
    assert_not @product.available_in_warehouse?(@warehouse, 15)
  end

  test "available_in_warehouse? should return false for non-existent stock" do
    new_warehouse = Warehouse.create!(name: "Empty Warehouse", user: @user)

    assert_not @product.available_in_warehouse?(new_warehouse, 1)
  end

  test "stock_in_warehouse should return correct quantity" do
    @product_stock.update!(quantity: 25)

    assert_equal 25, @product.stock_in_warehouse(@warehouse)
  end

  test "stock_in_warehouse should return 0 for non-existent stock" do
    new_warehouse = Warehouse.create!(name: "Empty Warehouse", user: @user)

    assert_equal 0, @product.stock_in_warehouse(new_warehouse)
  end

  test "total_stock should sum all warehouse quantities" do
    warehouse2 = Warehouse.create!(name: "Warehouse 2", user: @user)
    ProductStock.create!(product: @product, warehouse: warehouse2, quantity: 15)

    @product_stock.update!(quantity: 10)

    assert_equal 25, @product.total_stock
  end

  test "stock operations should handle invalid data gracefully" do
    initial_quantity = @product_stock.quantity

    # Try to set negative stock which should raise an error
    assert_raises(ArgumentError) do
      @product.update_stock!(@warehouse, -5, @user)
    end

    @product_stock.reload
    assert_equal initial_quantity, @product_stock.quantity, "Stock should not change if operation fails"
  end
end
