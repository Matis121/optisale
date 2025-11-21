class AddLimitsToCustomerPickupPoints < ActiveRecord::Migration[8.0]
  def change
    change_column :customer_pickup_points, :name, :string, limit: 100
    change_column :customer_pickup_points, :point_id, :string, limit: 50
    change_column :customer_pickup_points, :address, :string, limit: 100
    change_column :customer_pickup_points, :city, :string, limit: 50
    change_column :customer_pickup_points, :postcode, :string, limit: 10
    change_column :customer_pickup_points, :country, :string, limit: 50
  end
end
