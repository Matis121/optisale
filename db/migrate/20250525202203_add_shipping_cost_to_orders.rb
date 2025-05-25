class AddShippingCostToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :shipping_cost, :decimal
  end
end
