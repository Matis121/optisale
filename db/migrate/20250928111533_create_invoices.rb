class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.references :user, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.references :billing_integration, null: false, foreign_key: true
      t.string :invoice_number
      t.string :external_id
      t.string :status, default: 'draft'
      t.decimal :amount, precision: 10, scale: 2
      t.date :issue_date
      t.date :due_date
      t.string :external_url
      t.text :external_data

      t.timestamps
    end

    add_index :invoices, :invoice_number
    add_index :invoices, :external_id
    add_index :invoices, :status
    add_index :invoices, [ :user_id, :order_id ]
  end
end
