class AddMissingColumnsToBillingIntegrations < ActiveRecord::Migration[8.0]
  def change
    add_column :billing_integrations, :last_sync_at, :datetime
    add_column :billing_integrations, :error_message, :text
  end
end
