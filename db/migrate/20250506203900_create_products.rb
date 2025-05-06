class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name
      t.string :sku
      t.string :ean
      t.decimal :tax_rate
      t.decimal :nett_price
      t.decimal :gross_price

      t.timestamps
    end
  end
end
