require "test_helper"

class OrderProductControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get order_product_create_url
    assert_response :success
  end
end
