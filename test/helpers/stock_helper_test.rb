require "test_helper"

class StockHelperTest < ActionView::TestCase
  include StockHelper

  # Disable fixtures to avoid schema issues
  self.use_transactional_tests = false

  def setup
    # Skip fixture loading entirely
  end

  test "stock_status_badge should return correct badge for zero quantity" do
    result = stock_status_badge(0)

    assert_includes result, "badge badge-error badge-sm"
    assert_includes result, "Brak"
  end

  test "stock_status_badge should return correct badge for low quantity" do
    result = stock_status_badge(5)

    assert_includes result, "badge badge-warning badge-sm"
    assert_includes result, "Niski"
  end

  test "stock_status_badge should return correct badge for medium quantity" do
    result = stock_status_badge(25)

    assert_includes result, "badge badge-info badge-sm"
    assert_includes result, "Średni"
  end

  test "stock_status_badge should return correct badge for high quantity" do
    result = stock_status_badge(100)

    assert_includes result, "badge badge-success badge-sm"
    assert_includes result, "Wysoki"
  end

  test "stock_status_badge should handle boundary values correctly" do
    # Test exact boundary values
    assert_includes stock_status_badge(1), "Niski"
    assert_includes stock_status_badge(10), "Niski"
    assert_includes stock_status_badge(11), "Średni"
    assert_includes stock_status_badge(50), "Średni"
    assert_includes stock_status_badge(51), "Wysoki"
  end

  test "movement_type_badge should return correct badge for order_placement" do
    result = movement_type_badge("order_placement")

    assert_includes result, "badge badge-primary badge-outline badge-xs"
    assert_includes result, "Zamówienie"
  end

  test "movement_type_badge should return correct badge for stock_in" do
    result = movement_type_badge("stock_in")

    assert_includes result, "badge badge-success badge-outline badge-xs"
    assert_includes result, "Przyjęcie"
  end

  test "movement_type_badge should return correct badge for stock_out" do
    result = movement_type_badge("stock_out")

    assert_includes result, "badge badge-error badge-outline badge-xs"
    assert_includes result, "Wydanie"
  end

  test "movement_type_badge should return correct badge for manual_adjustment" do
    result = movement_type_badge("manual_adjustment")

    assert_includes result, "badge badge-warning badge-outline badge-xs"
    assert_includes result, "Korekta"
  end

  test "movement_type_badge should return correct badge for damage" do
    result = movement_type_badge("damage")

    assert_includes result, "badge badge-error badge-outline badge-xs"
    assert_includes result, "Uszkodzenie"
  end

  test "movement_type_badge should return correct badge for return" do
    result = movement_type_badge("return")

    assert_includes result, "badge badge-info badge-outline badge-xs"
    assert_includes result, "Zwrot"
  end

  test "movement_type_badge should handle unknown movement types" do
    result = movement_type_badge("unknown_type")

    assert_includes result, "badge badge-neutral badge-outline badge-xs"
    assert_includes result, "Unknown type" # humanized version
  end

  test "quantity_change_indicator should show positive quantities in green" do
    result = quantity_change_indicator(10)

    assert_includes result, "text-success font-mono"
    assert_includes result, "+10"
  end

  test "quantity_change_indicator should show negative quantities in red" do
    result = quantity_change_indicator(-5)

    assert_includes result, "text-error font-mono"
    assert_includes result, "-5"
  end

  test "quantity_change_indicator should show zero quantities in red" do
    result = quantity_change_indicator(0)

    assert_includes result, "text-error font-mono"
    assert_includes result, "0"
  end

  test "quantity_change_indicator should handle large numbers" do
    result = quantity_change_indicator(1000)

    assert_includes result, "+1000"

    result = quantity_change_indicator(-999)
    assert_includes result, "-999"
  end

  test "all helper methods should return html safe strings" do
    assert stock_status_badge(10).html_safe?
    assert movement_type_badge("stock_in").html_safe?
    assert quantity_change_indicator(5).html_safe?
  end

  test "all helper methods should handle nil input gracefully" do
    # These should not raise errors, though behavior might vary
    assert_nothing_raised do
      stock_status_badge(nil)
      movement_type_badge(nil)
      quantity_change_indicator(nil)
    end
  end

  test "helper methods should be properly escaped" do
    # Test with potentially dangerous input
    safe_result = movement_type_badge("<script>alert('xss')</script>")
    assert_not_includes safe_result, "<script>"

    # Should be properly escaped
    assert_includes safe_result, "&lt;script&gt;"
  end

  test "badges should have proper CSS classes structure" do
    # Test that all badges have the basic structure
    badge_methods = [
      -> { stock_status_badge(10) },
      -> { movement_type_badge("stock_in") },
      -> { quantity_change_indicator(5) }
    ]

    badge_methods.each do |method|
      result = method.call
      assert_includes result, "<span"
      assert_includes result, "class="
      assert_includes result, "</span>"
    end
  end
end
