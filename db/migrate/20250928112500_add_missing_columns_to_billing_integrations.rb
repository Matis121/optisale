class AddMissingColumnsToBillingIntegrations < ActiveRecord::Migration[8.0]
  def change
    # Skip if table doesn't exist (already migrated to invoicing_integrations)
    return unless table_exists?(:billing_integrations)

    add_column :billing_integrations, :last_sync_at, :datetime unless column_exists?(:billing_integrations, :last_sync_at)
    add_column :billing_integrations, :error_message, :text unless column_exists?(:billing_integrations, :error_message)
  end
end
