class AddIssuerAndSellerToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :seller, :text, limit: 250
    add_column :invoices, :issuer, :string, limit: 100
  end
end
