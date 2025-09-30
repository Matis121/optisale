class RenameBillingIntegrationIdToInvoicingIntegrationIdInInvoices < ActiveRecord::Migration[8.0]
  def up
    # Remove old foreign key constraint
    remove_foreign_key :invoices, :invoicing_integrations, column: :billing_integration_id

    # Rename column
    rename_column :invoices, :billing_integration_id, :invoicing_integration_id

    # Add new foreign key constraint
    add_foreign_key :invoices, :invoicing_integrations, column: :invoicing_integration_id
  end

  def down
    # Remove new foreign key constraint
    remove_foreign_key :invoices, :invoicing_integrations, column: :invoicing_integration_id

    # Rename column back
    rename_column :invoices, :invoicing_integration_id, :billing_integration_id

    # Add back old foreign key constraint
    add_foreign_key :invoices, :invoicing_integrations, column: :billing_integration_id
  end
end
