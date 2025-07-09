class CreateProductPrices < ActiveRecord::Migration[8.0]
  def change
    create_table :product_prices do |t|
      t.references :product, null: false, foreign_key: true
      t.references :price_group, null: false, foreign_key: true
      t.decimal :nett_price
      t.decimal :gross_price
      t.string :currency

      t.timestamps
    end
  end
end
