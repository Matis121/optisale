class AddShippingToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :shipping_method, :string
  end
end
