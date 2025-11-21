class ChangeLimitInCountryForAddresses < ActiveRecord::Migration[8.0]
  def change
    change_column :addresses, :country, :string, limit: 50
    change_column :invoices, :invoice_country, :string, limit: 50
  end
end
