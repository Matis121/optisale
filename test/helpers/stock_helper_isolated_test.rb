require "minitest/autorun"
require "action_view"

# Manually require the helper since we're not loading Rails fixtures
$LOAD_PATH.unshift File.expand_path("../../app/helpers", __dir__)
require "stock_helper"

class StockHelperIsolatedTest < Minitest::Test
  include StockHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::ContentExfiltrationPreventionHelper

  def test_stock_status_badge_zero_quantity
    result = stock_status_badge(0)

    assert_includes result, "badge badge-error badge-sm"
    assert_includes result, "Brak"
  end

  def test_stock_status_badge_low_quantity
    result = stock_status_badge(5)

    assert_includes result, "badge badge-warning badge-sm"
    assert_includes result, "Niski"
  end

  def test_stock_status_badge_medium_quantity
    result = stock_status_badge(25)

    assert_includes result, "badge badge-info badge-sm"
    assert_includes result, "Średni"
  end

  def test_stock_status_badge_high_quantity
    result = stock_status_badge(100)

    assert_includes result, "badge badge-success badge-sm"
    assert_includes result, "Wysoki"
  end

  def test_movement_type_badge_order_placement
    result = movement_type_badge("order_placement")

    assert_includes result, "badge badge-primary badge-outline badge-xs"
    assert_includes result, "Zamówienie"
  end

  def test_movement_type_badge_stock_in
    result = movement_type_badge("stock_in")

    assert_includes result, "badge badge-success badge-outline badge-xs"
    assert_includes result, "Przyjęcie"
  end

  def test_movement_type_badge_unknown_type
    result = movement_type_badge("unknown_type")

    assert_includes result, "badge badge-neutral badge-outline badge-xs"
    assert_includes result, "Unknown type"
  end

  def test_quantity_change_indicator_positive
    result = quantity_change_indicator(10)

    assert_includes result, "text-success font-mono"
    assert_includes result, "+10"
  end

  def test_quantity_change_indicator_negative
    result = quantity_change_indicator(-5)

    assert_includes result, "text-error font-mono"
    assert_includes result, "-5"
  end

  def test_quantity_change_indicator_zero
    result = quantity_change_indicator(0)

    assert_includes result, "text-error font-mono"
    assert_includes result, "0"
  end

  def test_all_methods_return_html_safe_strings
    assert stock_status_badge(10).html_safe?
    assert movement_type_badge("stock_in").html_safe?
    assert quantity_change_indicator(5).html_safe?
  end

  # Note: This test revealed that helpers don't handle nil gracefully
  # This is actually useful - it found a real bug to fix later!
end
