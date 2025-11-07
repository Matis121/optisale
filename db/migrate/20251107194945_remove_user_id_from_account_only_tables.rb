class RemoveUserIdFromAccountOnlyTables < ActiveRecord::Migration[8.0]
  def change
    # Remove user_id from catalogs (belongs only to account)
    remove_foreign_key :catalogs, :users if foreign_key_exists?(:catalogs, :users)
    remove_index :catalogs, :user_id if index_exists?(:catalogs, :user_id)
    remove_column :catalogs, :user_id, :bigint

    # Remove user_id from order_status_groups (belongs only to account)
    remove_foreign_key :order_status_groups, :users if foreign_key_exists?(:order_status_groups, :users)
    remove_index :order_status_groups, :user_id if index_exists?(:order_status_groups, :user_id)
    remove_column :order_status_groups, :user_id, :bigint

    # Remove user_id from order_statuses (belongs only to account)
    remove_foreign_key :order_statuses, :users if foreign_key_exists?(:order_statuses, :users)
    remove_index :order_statuses, [:user_id, :position] if index_exists?(:order_statuses, [:user_id, :position])
    remove_index :order_statuses, :user_id if index_exists?(:order_statuses, :user_id)
    remove_column :order_statuses, :user_id, :bigint

    # Remove user_id from price_groups (belongs only to account)
    remove_foreign_key :price_groups, :users if foreign_key_exists?(:price_groups, :users)
    remove_index :price_groups, :user_id if index_exists?(:price_groups, :user_id)
    remove_column :price_groups, :user_id, :bigint

    # Remove user_id from warehouses (belongs only to account)
    remove_foreign_key :warehouses, :users if foreign_key_exists?(:warehouses, :users)
    remove_index :warehouses, :user_id if index_exists?(:warehouses, :user_id)
    remove_column :warehouses, :user_id, :bigint

    # Remove user_id from invoicing_integrations (belongs only to account)
    remove_foreign_key :invoicing_integrations, :users if foreign_key_exists?(:invoicing_integrations, :users)
    remove_index :invoicing_integrations, [:user_id, :provider] if index_exists?(:invoicing_integrations, [:user_id, :provider])
    remove_index :invoicing_integrations, :user_id if index_exists?(:invoicing_integrations, :user_id)
    remove_column :invoicing_integrations, :user_id, :bigint

    # Note: We keep user_id in:
    # - orders (audit: who created the order)
    # - invoices (audit: who created the invoice)
    # - stock_movements (audit: who performed the stock movement)
  end
end
