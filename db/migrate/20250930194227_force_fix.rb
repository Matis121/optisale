class ForceFix < ActiveRecord::Migration[8.0]
  def up
    # Usuń wszystkie foreign keys do billing_integrations
    execute "ALTER TABLE invoices DROP CONSTRAINT IF EXISTS fk_rails_invoices_billing_integrations;"
    execute "ALTER TABLE invoices DROP CONSTRAINT IF EXISTS invoices_billing_integration_id_fkey;"

    # Usuń tabelę z CASCADE
    execute "DROP TABLE IF EXISTS billing_integrations CASCADE;"

    # Oznacz inne migracje jako wykonane
    execute "INSERT INTO schema_migrations (version) VALUES ('20250930163659') ON CONFLICT DO NOTHING;"
    execute "INSERT INTO schema_migrations (version) VALUES ('20250930164718') ON CONFLICT DO NOTHING;"
    execute "INSERT INTO schema_migrations (version) VALUES ('20250930182709') ON CONFLICT DO NOTHING;"
    execute "INSERT INTO schema_migrations (version) VALUES ('20250930184757') ON CONFLICT DO NOTHING;"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
