class AddAccountAndRoleToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :account, null: true, foreign_key: true
    add_column :users, :role, :string, default: 'owner', null: false
  end
end
