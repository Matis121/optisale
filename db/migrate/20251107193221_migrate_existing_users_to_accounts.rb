class MigrateExistingUsersToAccounts < ActiveRecord::Migration[8.0]
  def up
    # For each existing user, create an Account and migrate their data
    execute <<-SQL
      INSERT INTO accounts (name, created_at, updated_at)
      SELECT email, created_at, updated_at FROM users;
    SQL

    # Update users with their new account_id
    User.reset_column_information
    Account.reset_column_information
    
    User.find_each do |user|
      account = Account.find_by(name: user.email)
      user.update_column(:account_id, account.id) if account
    end

    # Migrate orders
    execute <<-SQL
      UPDATE orders 
      SET account_id = users.account_id 
      FROM users 
      WHERE orders.user_id = users.id;
    SQL

    # Migrate catalogs
    execute <<-SQL
      UPDATE catalogs 
      SET account_id = users.account_id 
      FROM users 
      WHERE catalogs.user_id = users.id;
    SQL

    # Migrate warehouses
    execute <<-SQL
      UPDATE warehouses 
      SET account_id = users.account_id 
      FROM users 
      WHERE warehouses.user_id = users.id;
    SQL

    # Migrate price_groups
    execute <<-SQL
      UPDATE price_groups 
      SET account_id = users.account_id 
      FROM users 
      WHERE price_groups.user_id = users.id;
    SQL

    # Migrate order_statuses
    execute <<-SQL
      UPDATE order_statuses 
      SET account_id = users.account_id 
      FROM users 
      WHERE order_statuses.user_id = users.id;
    SQL

    # Migrate order_status_groups
    execute <<-SQL
      UPDATE order_status_groups 
      SET account_id = users.account_id 
      FROM users 
      WHERE order_status_groups.user_id = users.id;
    SQL

    # Migrate invoicing_integrations
    execute <<-SQL
      UPDATE invoicing_integrations 
      SET account_id = users.account_id 
      FROM users 
      WHERE invoicing_integrations.user_id = users.id;
    SQL

    # Migrate invoices
    execute <<-SQL
      UPDATE invoices 
      SET account_id = users.account_id 
      FROM users 
      WHERE invoices.user_id = users.id;
    SQL

    # Migrate stock_movements
    execute <<-SQL
      UPDATE stock_movements 
      SET account_id = users.account_id 
      FROM users 
      WHERE stock_movements.user_id = users.id;
    SQL
  end

  def down
    # Reversing this migration would be complex and potentially data-losing
    raise ActiveRecord::IrreversibleMigration
  end
end
