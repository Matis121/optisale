class AddNipToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :nip, :string
  end
end
