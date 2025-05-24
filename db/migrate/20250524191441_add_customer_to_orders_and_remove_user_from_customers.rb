class AddCustomerToOrdersAndRemoveUserFromCustomers < ActiveRecord::Migration[8.0]
  def change
    add_reference :orders, :customer, foreign_key: true
    remove_reference :customers, :user, foreign_key: true
  end
end
