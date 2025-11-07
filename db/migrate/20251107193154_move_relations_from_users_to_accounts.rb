class MoveRelationsFromUsersToAccounts < ActiveRecord::Migration[8.0]
  def change
    # Add account_id to tables that currently have user_id
    add_reference :orders, :account, null: true, foreign_key: true
    add_reference :catalogs, :account, null: true, foreign_key: true
    add_reference :warehouses, :account, null: true, foreign_key: true
    add_reference :price_groups, :account, null: true, foreign_key: true
    add_reference :order_statuses, :account, null: true, foreign_key: true
    add_reference :order_status_groups, :account, null: true, foreign_key: true
    add_reference :invoicing_integrations, :account, null: true, foreign_key: true
    add_reference :invoices, :account, null: true, foreign_key: true
    add_reference :stock_movements, :account, null: true, foreign_key: true
  end
end
