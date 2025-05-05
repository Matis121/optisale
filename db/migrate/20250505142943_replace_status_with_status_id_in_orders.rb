class ReplaceStatusWithStatusIdInOrders < ActiveRecord::Migration[8.0]
  def change
    remove_column :orders, :status, :string
    add_column :orders, :status_id, :integer
  end
end
