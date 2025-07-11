require "test_helper"

class Storage::WarehousesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get storage_warehouses_index_url
    assert_response :success
  end

  test "should get show" do
    get storage_warehouses_show_url
    assert_response :success
  end

  test "should get new" do
    get storage_warehouses_new_url
    assert_response :success
  end

  test "should get edit" do
    get storage_warehouses_edit_url
    assert_response :success
  end

  test "should get create" do
    get storage_warehouses_create_url
    assert_response :success
  end

  test "should get update" do
    get storage_warehouses_update_url
    assert_response :success
  end

  test "should get destroy" do
    get storage_warehouses_destroy_url
    assert_response :success
  end
end
