class AddNewColumnsToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :invoice_fullname, :string, null: false
    add_column :invoices, :invoice_company, :string
    add_column :invoices, :invoice_nip, :string
    add_column :invoices, :invoice_street, :string, null: false
    add_column :invoices, :invoice_city, :string, null: false
    add_column :invoices, :invoice_postcode, :string, null: false
    add_column :invoices, :invoice_country, :string, default: "PL"

    add_column :invoices, :sub_id, :integer, null: false
    add_column :invoices, :month, :integer, null: false
    add_column :invoices, :year, :integer, null: false

    add_column :invoices, :total_price_brutto, :decimal, precision: 10, scale: 2, null: false
    add_column :invoices, :total_price_netto, :decimal, precision: 10, scale: 2, null: false
    add_column :invoices, :currency, :string, default: "PLN", null: false

    add_column :invoices, :payment_method, :string, null: false
    add_column :invoices, :additional_info, :text

    add_column :invoices, :date_add, :datetime, null: false
    add_column :invoices, :date_sell, :datetime, null: false
    add_column :invoices, :date_pay_to, :datetime


    remove_column :invoices, :amount, :decimal
    remove_column :invoices, :issue_date, :date
    remove_column :invoices, :due_date, :date
  end
end
