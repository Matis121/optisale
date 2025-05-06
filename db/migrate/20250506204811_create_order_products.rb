class CreateOrderProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :order_products do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: true, foreign_key: true
      t.string :name
      t.string :sku
      t.string :ean
      t.integer :quantity
      t.decimal :gross_price
      t.decimal :nett_price
      t.decimal :tax_rate

      t.timestamps
    end
  end
end
