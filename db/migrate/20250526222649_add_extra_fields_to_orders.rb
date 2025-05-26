class AddExtraFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :extra_field_1, :string, limit: 50
    add_column :orders, :extra_field_2, :string, limit: 50
    add_column :orders, :admin_comments, :string, limit: 150
  end
end
