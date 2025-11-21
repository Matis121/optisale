class RemoveInvoicingIntegrationsIdFromInvoices < ActiveRecord::Migration[8.0]
  def change
    remove_column :invoices, :invoicing_integration_id, :bigint
  end
end
