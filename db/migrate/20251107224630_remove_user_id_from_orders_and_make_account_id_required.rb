class RemoveUserIdFromOrdersAndMakeAccountIdRequired < ActiveRecord::Migration[8.0]
  def change
    remove_column :orders, :user_id
    change_column_null :orders, :account_id, false
  end
end
