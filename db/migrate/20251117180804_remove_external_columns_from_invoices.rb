class RemoveExternalColumnsFromInvoices < ActiveRecord::Migration[8.0]
  def change
    remove_column :invoices, :external_url
    remove_column :invoices, :external_data

    add_column :invoices, :external_invoice_number, :string, limit: 30
    change_column :invoices, :external_id, :string, limit: 30
  end
end
