class MigrateBillingIntegrationsToInvoicingIntegrations < ActiveRecord::Migration[8.0]
  def up
    # Skip if source table doesn't exist
    return unless table_exists?(:billing_integrations)

    # Migrate data from billing_integrations to invoicing_integrations
    execute <<-SQL
      INSERT INTO invoicing_integrations (
        user_id, provider, name, active, encrypted_credentials,#{' '}
        configuration, status, last_sync_at, error_message,#{' '}
        created_at, updated_at
      )
      SELECT#{' '}
        user_id, provider, name, active, encrypted_credentials,
        configuration, status, last_sync_at, error_message,
        created_at, updated_at
      FROM billing_integrations
    SQL

    # Update invoices to reference new invoicing_integrations
    execute <<-SQL
      UPDATE invoices#{' '}
      SET billing_integration_id = (
        SELECT ii.id#{' '}
        FROM invoicing_integrations ii#{' '}
        WHERE ii.user_id = invoices.user_id#{' '}
        AND ii.provider = (
          SELECT bi.provider#{' '}
          FROM billing_integrations bi#{' '}
          WHERE bi.id = invoices.billing_integration_id
        )
        LIMIT 1
      )
    SQL
  end

  def down
    # Remove migrated data
    execute "DELETE FROM invoicing_integrations"

    # Note: We don't restore invoices.billing_integration_id as it would be complex
    # and the old billing_integrations table still exists
  end
end
