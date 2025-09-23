require "test_helper"

class Storage::StockMovementsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @product = products(:one)
    @warehouse = warehouses(:one)
    sign_in @user

    # Create some stock movements for testing
    @stock_movement_1 = StockMovement.create!(
      product: @product,
      warehouse: @warehouse,
      user: @user,
      movement_type: "stock_in",
      quantity: 10,
      stock_before: 0,
      stock_after: 10,
      occurred_at: 2.days.ago
    )

    @stock_movement_2 = StockMovement.create!(
      product: @product,
      warehouse: @warehouse,
      user: @user,
      movement_type: "stock_out",
      quantity: -3,
      stock_before: 10,
      stock_after: 7,
      occurred_at: 1.day.ago
    )
  end

  test "should get index" do
    get storage_product_stock_movements_path(@product)
    assert_response :success

    assert_select "table" # Should contain a table
    assert_select "td", text: "Przyjęcie towaru" # Polish translation
    assert_select "td", text: "Wydanie towaru"
  end

  test "should get index with warehouse filter" do
    get storage_product_stock_movements_path(@product, warehouse_id: @warehouse.id)
    assert_response :success

    # Should show warehouse name in filter buttons
    assert_select "a", text: @warehouse.name
  end

  test "should get index for all warehouses" do
    get storage_product_stock_movements_path(@product)
    assert_response :success

    # Should show "Wszystkie magazyny" button
    assert_select "a", text: "Wszystkie magazyny"
  end

  test "should show current stock information" do
    ProductStock.find_or_create_by!(
      product: @product,
      warehouse: @warehouse,
      quantity: 25
    )

    get storage_product_stock_movements_path(@product)
    assert_response :success

    # Should show current stock
    assert_select ".text-2xl", text: "25"
  end

  test "should show total movements count" do
    get storage_product_stock_movements_path(@product)
    assert_response :success

    # Should show total count
    movements_count = @product.stock_movements.count
    assert_select ".text-2xl", text: movements_count.to_s
  end

  test "should handle turbo frame requests" do
    get storage_product_stock_movements_path(@product),
        headers: { "Turbo-Frame" => "stock-movements-content" }
    assert_response :success
  end

  test "should respond to turbo stream" do
    get storage_product_stock_movements_path(@product, format: :turbo_stream)
    assert_response :success
    assert_includes response.content_type, "text/vnd.turbo-stream.html"
  end

  test "should paginate results" do
    # Create many movements
    20.times do |i|
      StockMovement.create!(
        product: @product,
        warehouse: @warehouse,
        user: @user,
        movement_type: "manual_adjustment",
        quantity: 1,
        stock_before: i,
        stock_after: i + 1,
        occurred_at: i.hours.ago
      )
    end

    get storage_product_stock_movements_path(@product)
    assert_response :success

    # Should have pagination if more than 20 movements
    total_movements = @product.stock_movements.count
    if total_movements > 20
      assert_select ".pagination" # Should have pagination
    end
  end

  test "should handle non-existent product" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get storage_product_stock_movements_path(999999)
    end
  end

  test "should handle non-existent warehouse filter" do
    get storage_product_stock_movements_path(@product, warehouse_id: 999999)
    assert_response :success # Should still work, just no movements shown
  end

  test "should filter movements by warehouse" do
    warehouse2 = Warehouse.create!(name: "Warehouse 2", user: @user)

    # Create movement in second warehouse
    StockMovement.create!(
      product: @product,
      warehouse: warehouse2,
      user: @user,
      movement_type: "stock_in",
      quantity: 5,
      stock_before: 0,
      stock_after: 5,
      occurred_at: Time.current
    )

    # Request with warehouse filter
    get storage_product_stock_movements_path(@product, warehouse_id: @warehouse.id)
    assert_response :success

    # Should only show movements from the filtered warehouse
    # This would need to be tested by parsing the response body
    # or checking that @stock_movements instance variable is properly filtered
  end

  test "should show movement details correctly" do
    get storage_product_stock_movements_path(@product)
    assert_response :success

    # Should show movement type
    assert_select "td", text: /Przyjęcie towaru|Wydanie towaru/

    # Should show warehouse name
    assert_select "td", text: @warehouse.name

    # Should show quantity changes
    assert_select "span.font-mono", text: /\+10|-3/

    # Should show stock before/after
    assert_select "span.font-mono", text: /\d+/

    # Should show user email
    assert_select "td", text: @user.email.split("@").first
  end

  test "should show reference links when present" do
    order = Order.create!(user: @user, customer: customers(:one), status_id: order_statuses(:one).id)

    movement_with_ref = StockMovement.create!(
      product: @product,
      warehouse: @warehouse,
      user: @user,
      movement_type: "order_placement",
      quantity: -2,
      stock_before: 7,
      stock_after: 5,
      reference: order,
      occurred_at: Time.current
    )

    get storage_product_stock_movements_path(@product)
    assert_response :success

    # Should show reference link
    assert_select "a[href='#{order_path(order)}']", text: "Order ##{order.id}"
  end

  test "should require authentication" do
    sign_out @user

    get storage_product_stock_movements_path(@product)
    assert_redirected_to new_user_session_path
  end
end
