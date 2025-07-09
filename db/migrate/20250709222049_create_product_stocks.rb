class CreateProductStocks < ActiveRecord::Migration[8.0]
  def change
    create_table :product_stocks do |t|
      t.references :product, null: false, foreign_key: true
      t.references :warehouse, null: false, foreign_key: true
      t.integer :quantity

      t.timestamps
    end
  end
end
