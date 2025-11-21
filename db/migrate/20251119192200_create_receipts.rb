class CreateReceipts < ActiveRecord::Migration[8.0]
  def change
    create_table :receipts do |t|
      t.references :account, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.string :status, limit: 30
      t.string :receipt_number, limit: 30
      t.integer :series_id
      t.integer :year, null: false
      t.integer :month, null: false
      t.integer :sub_id, null: false
      t.datetime :date_add, null: false
      t.string :payment_method, limit: 30, null: false
      t.string :nip, limit: 30
      t.string :currency, limit: 3, null: false
      t.decimal :total_price_brutto, precision: 10, scale: 2, null: false
      t.string :external_receipt_number, limit: 30
      t.string :external_id, limit: 30

      t.timestamps
    end
  end
end
