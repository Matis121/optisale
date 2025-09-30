class ActuallyRenameBillingToInvoicingIntegrationId < ActiveRecord::Migration[8.0]
  def up
    # Sprawdź czy kolumna billing_integration_id istnieje
    if column_exists?(:invoices, :billing_integration_id)
      # Usuń stary foreign key jeśli istnieje
      if foreign_key_exists?(:invoices, column: :billing_integration_id)
        remove_foreign_key :invoices, column: :billing_integration_id
      end

      # Zmień nazwę kolumny
      rename_column :invoices, :billing_integration_id, :invoicing_integration_id

      # Dodaj nowy foreign key
      add_foreign_key :invoices, :invoicing_integrations, column: :invoicing_integration_id

      # Zmień nazwę indeksu jeśli istnieje
      if index_exists?(:invoices, :billing_integration_id, name: 'index_invoices_on_billing_integration_id')
        rename_index :invoices, :index_invoices_on_billing_integration_id, :index_invoices_on_invoicing_integration_id
      end
    end
  end

  def down
    if column_exists?(:invoices, :invoicing_integration_id)
      # Usuń foreign key
      if foreign_key_exists?(:invoices, column: :invoicing_integration_id)
        remove_foreign_key :invoices, column: :invoicing_integration_id
      end

      # Zmień nazwę kolumny z powrotem
      rename_column :invoices, :invoicing_integration_id, :billing_integration_id

      # Zmień nazwę indeksu z powrotem
      if index_exists?(:invoices, :invoicing_integration_id, name: 'index_invoices_on_invoicing_integration_id')
        rename_index :invoices, :index_invoices_on_invoicing_integration_id, :index_invoices_on_billing_integration_id
      end
    end
  end
end
