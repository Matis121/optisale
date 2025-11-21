class CreateReceiptItems < ActiveRecord::Migration[8.0]
  def change
    create_table :receipt_items do |t|
      t.references :receipt, null: false, foreign_key: true
      t.string :name, limit: 200, null: false
      t.string :sku, limit: 50
      t.string :ean, limit: 32
      t.decimal :price_brutto, precision: 10, scale: 2, null: false
      t.decimal :tax_rate, precision: 3, scale: 1, null: false
      t.integer :quantity, null: false

      t.timestamps
    end
  end
end
