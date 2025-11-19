class AdjustInvoiceColumnLimits < ActiveRecord::Migration[8.0]
  def change
    change_column :invoices, :status, :string, limit: 30
    change_column :invoices, :invoice_number, :string, limit: 30
    change_column :invoices, :invoice_fullname, :string, limit: 100
    change_column :invoices, :invoice_company, :string, limit: 100
    change_column :invoices, :invoice_nip, :string, limit: 100
    change_column :invoices, :invoice_street, :string, limit: 100
    change_column :invoices, :invoice_postcode, :string, limit: 100
    change_column :invoices, :invoice_city, :string, limit: 100
    change_column :invoices, :invoice_country, :string, limit: 20
    change_column :invoices, :currency, :string, limit: 3
    change_column :invoices, :payment_method, :string, limit: 100
    change_column :invoices, :additional_info, :string, limit: 500
  end
end
