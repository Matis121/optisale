class ChangeSellerToStringInInvoices < ActiveRecord::Migration[8.0]
  def change
    change_column :invoices, :seller, :string, limit: 250
  end
end
