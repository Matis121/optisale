class AddOrderStatusGroupToOrderStatuses < ActiveRecord::Migration[8.0]
  def change
    add_reference :order_statuses, :order_status_group, null: true, foreign_key: true
  end
end
