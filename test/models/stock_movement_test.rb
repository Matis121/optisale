require "test_helper"

class StockMovementTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @product = products(:one)
    @warehouse = warehouses(:one)
  end

  test "should create stock movement with valid attributes" do
    stock_movement = StockMovement.new(
      product: @product,
      warehouse: @warehouse,
      user: @user,
      movement_type: "stock_in",
      quantity: 10,
      stock_before: 5,
      stock_after: 15,
      occurred_at: Time.current
    )

    assert stock_movement.save
    assert_equal "stock_in", stock_movement.movement_type
    assert_equal 10, stock_movement.quantity
  end

  test "should require movement_type" do
    stock_movement = StockMovement.new(
      product: @product,
      warehouse: @warehouse,
      user: @user,
      quantity: 10,
      stock_before: 5,
      stock_after: 15,
      occurred_at: Time.current
    )

    assert_not stock_movement.save
    assert_includes stock_movement.errors[:movement_type], "can't be blank"
  end

  test "should validate movement_type inclusion" do
    stock_movement = StockMovement.new(
      product: @product,
      warehouse: @warehouse,
      user: @user,
      movement_type: "invalid_type",
      quantity: 10,
      stock_before: 5,
      stock_after: 15,
      occurred_at: Time.current
    )

    assert_not stock_movement.save
    assert_includes stock_movement.errors[:movement_type], "is not included in the list"
  end

  test "should require quantity to be non-zero" do
    stock_movement = StockMovement.new(
      product: @product,
      warehouse: @warehouse,
      user: @user,
      movement_type: "stock_in",
      quantity: 0,
      stock_before: 5,
      stock_after: 5,
      occurred_at: Time.current
    )

    assert_not stock_movement.save
    assert_includes stock_movement.errors[:quantity], "must be other than 0"
  end

  test "should validate stock_before is non-negative" do
    stock_movement = StockMovement.new(
      product: @product,
      warehouse: @warehouse,
      user: @user,
      movement_type: "stock_in",
      quantity: 10,
      stock_before: -1,
      stock_after: 9,
      occurred_at: Time.current
    )

    assert_not stock_movement.save
    assert_includes stock_movement.errors[:stock_before], "must be greater than or equal to 0"
  end

  test "should validate stock_after is non-negative" do
    stock_movement = StockMovement.new(
      product: @product,
      warehouse: @warehouse,
      user: @user,
      movement_type: "stock_out",
      quantity: -10,
      stock_before: 5,
      stock_after: -5,
      occurred_at: Time.current
    )

    assert_not stock_movement.save
    assert_includes stock_movement.errors[:stock_after], "must be greater than or equal to 0"
  end

  test "stock_increase? should return true for positive quantity" do
    stock_movement = StockMovement.new(quantity: 10)
    assert stock_movement.stock_increase?
  end

  test "stock_decrease? should return true for negative quantity" do
    stock_movement = StockMovement.new(quantity: -5)
    assert stock_movement.stock_decrease?
  end

  test "display_type should return proper Polish translation" do
    stock_movement = StockMovement.new(movement_type: "stock_in")
    assert_equal "Przyjęcie towaru", stock_movement.display_type

    stock_movement.movement_type = "order_placement"
    assert_equal "Zamówienie", stock_movement.display_type

    stock_movement.movement_type = "damage"
    assert_equal "Uszkodzenie", stock_movement.display_type
  end

  test "scopes should work correctly" do
    # Create test movements
    StockMovement.create!(
      product: @product,
      warehouse: @warehouse,
      user: @user,
      movement_type: "stock_in",
      quantity: 10,
      stock_before: 0,
      stock_after: 10,
      occurred_at: 2.days.ago
    )

    StockMovement.create!(
      product: @product,
      warehouse: @warehouse,
      user: @user,
      movement_type: "stock_out",
      quantity: -3,
      stock_before: 10,
      stock_after: 7,
      occurred_at: 1.day.ago
    )

    # Test scopes
    assert StockMovement.for_product(@product).count >= 2
    assert StockMovement.for_warehouse(@warehouse).count >= 2
    assert StockMovement.by_type("stock_in").count >= 1

    # Test recent scope (should be ordered by occurred_at desc)
    recent_movements = StockMovement.recent.limit(2)
    assert recent_movements.first.occurred_at >= recent_movements.second.occurred_at
  end
end
