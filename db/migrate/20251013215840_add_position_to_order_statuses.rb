class AddPositionToOrderStatuses < ActiveRecord::Migration[8.0]
  def change
    add_column :order_statuses, :position, :integer, default: 0
    add_index :order_statuses, [ :user_id, :position ]
  end
end
