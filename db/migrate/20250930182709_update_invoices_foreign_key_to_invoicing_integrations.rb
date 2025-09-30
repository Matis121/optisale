class UpdateInvoicesForeignKeyToInvoicingIntegrations < ActiveRecord::Migration[8.0]
  def up
    # Remove old foreign key constraint
    remove_foreign_key :invoices, :billing_integrations

    # Add new foreign key constraint to invoicing_integrations
    add_foreign_key :invoices, :invoicing_integrations, column: :billing_integration_id
  end

  def down
    # Remove new foreign key constraint
    remove_foreign_key :invoices, :invoicing_integrations

    # Add back old foreign key constraint (this will fail if billing_integrations doesn't exist)
    # add_foreign_key :invoices, :billing_integrations, column: :billing_integration_id
  end
end
