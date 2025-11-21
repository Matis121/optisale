class AddNipToAddresses < ActiveRecord::Migration[8.0]
  def change
    add_column :addresses, :nip, :string, limit: 100
  end
end
