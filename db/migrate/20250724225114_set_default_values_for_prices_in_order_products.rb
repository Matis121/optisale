class SetDefaultValuesForPricesInOrderProducts < ActiveRecord::Migration[8.0]
  def change
    change_column :order_products, :gross_price, :decimal, precision: 10, scale: 2, default: 0.00
    change_column :order_products, :nett_price, :decimal, precision: 10, scale: 2, default: 0.00
    change_column :order_products, :tax_rate, :decimal, precision: 3, scale: 1, default: 0.0
  end
end
