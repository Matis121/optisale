class AddDefaultToOrderStatuses < ActiveRecord::Migration[8.0]
  def change
    add_column :order_statuses, :default, :boolean, default: false, null: false
    add_index :order_statuses, [ :user_id, :default ]
  end
end
