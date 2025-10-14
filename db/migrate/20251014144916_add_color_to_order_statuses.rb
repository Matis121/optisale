class AddColorToOrderStatuses < ActiveRecord::Migration[8.0]
  def change
    add_column :order_statuses, :color, :string
  end
end
