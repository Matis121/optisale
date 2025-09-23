require "test_helper"

class Storage::ProductsControllerManualStockTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  def setup
    @user = users(:one)
    @product = products(:one)
    @warehouse = warehouses(:one)
    sign_in @user

    # Clear existing stock movements and set initial stock
    StockMovement.where(product: @product).destroy_all
    @product_stock = ProductStock.find_or_create_by!(
      product: @product,
      warehouse: @warehouse
    )
    @product_stock.update!(quantity: 10)
  end

  test "should create stock movement when manually updating product stock" do
    initial_movements_count = StockMovement.count

    # Simulate manual stock update through product form
    patch storage_product_path(@product), params: {
      product: {
        name: @product.name,
        product_stocks_attributes: {
          "0" => {
            id: @product_stock.id,
            warehouse_id: @warehouse.id,
            quantity: "25"  # Increase from 10 to 25
          }
        }
      }
    }

    assert_redirected_to storage_products_path

    # Should create exactly one new stock movement
    assert_equal initial_movements_count + 1, StockMovement.count

    # Check the created movement
    movement = StockMovement.last
    assert_equal @product, movement.product
    assert_equal @warehouse, movement.warehouse
    assert_equal @user, movement.user
    assert_equal "manual_adjustment", movement.movement_type
    assert_equal 15, movement.quantity  # 25 - 10 = +15
    assert_equal 10, movement.stock_before
    assert_equal 25, movement.stock_after

    # Verify the product stock was actually updated
    @product_stock.reload
    assert_equal 25, @product_stock.quantity
  end

  test "should create negative stock movement when reducing stock manually" do
    initial_movements_count = StockMovement.count

    # Reduce stock from 10 to 3
    patch storage_product_path(@product), params: {
      product: {
        name: @product.name,
        product_stocks_attributes: {
          "0" => {
            id: @product_stock.id,
            warehouse_id: @warehouse.id,
            quantity: "3"  # Decrease from 10 to 3
          }
        }
      }
    }

    assert_redirected_to storage_products_path

    # Should create exactly one new stock movement
    assert_equal initial_movements_count + 1, StockMovement.count

    # Check the created movement
    movement = StockMovement.last
    assert_equal @product, movement.product
    assert_equal @warehouse, movement.warehouse
    assert_equal @user, movement.user
    assert_equal "manual_adjustment", movement.movement_type
    assert_equal -7, movement.quantity  # 3 - 10 = -7
    assert_equal 10, movement.stock_before
    assert_equal 3, movement.stock_after
  end

  test "should not create stock movement when quantity unchanged" do
    initial_movements_count = StockMovement.count

    # Update product without changing stock quantity
    patch storage_product_path(@product), params: {
      product: {
        name: "Updated Product Name",  # Only change name
        product_stocks_attributes: {
          "0" => {
            id: @product_stock.id,
            warehouse_id: @warehouse.id,
            quantity: "10"  # Same as current quantity
          }
        }
      }
    }

    assert_redirected_to storage_products_path

    # Should NOT create any new stock movement
    assert_equal initial_movements_count, StockMovement.count

    # But product name should be updated
    @product.reload
    assert_equal "Updated Product Name", @product.name
  end

  test "should handle multiple warehouse stock updates" do
    # Create second warehouse and product stock
    warehouse2 = Warehouse.create!(name: "Warehouse 2", user: @user, default: false)
    product_stock2 = ProductStock.create!(
      product: @product,
      warehouse: warehouse2,
      quantity: 5
    )

    initial_movements_count = StockMovement.count

    # Update both warehouses at once
    patch storage_product_path(@product), params: {
      product: {
        name: @product.name,
        product_stocks_attributes: {
          "0" => {
            id: @product_stock.id,
            warehouse_id: @warehouse.id,
            quantity: "20"  # 10 -> 20
          },
          "1" => {
            id: product_stock2.id,
            warehouse_id: warehouse2.id,
            quantity: "15"  # 5 -> 15
          }
        }
      }
    }

    assert_redirected_to storage_products_path

    # Should create two new stock movements
    assert_equal initial_movements_count + 2, StockMovement.count

    # Check movements were created for both warehouses
    movements = StockMovement.last(2)
    warehouse_ids = movements.map(&:warehouse_id)
    assert_includes warehouse_ids, @warehouse.id
    assert_includes warehouse_ids, warehouse2.id
  end
end
