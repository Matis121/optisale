class SetDefaultColorsForExistingOrderStatuses < ActiveRecord::Migration[8.0]
  def up
    OrderStatus.reset_column_information
    OrderStatus.where(color: nil).update_all(color: "#667EEA")

    change_column_null :order_statuses, :color, false
    change_column_default :order_statuses, :color, "#667EEA"
  end
end
