class RemoveTotalAmountFromOrders < ActiveRecord::Migration[8.0]
  def change
    remove_column :orders, :total_amount, :decimal
  end
end
