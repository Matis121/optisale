class RemoveNettPriceFromTables < ActiveRecord::Migration[8.0]
  def change
    # Remove nett_price from product_prices table
    remove_column :product_prices, :nett_price, :decimal

    # Remove nett_price from order_products table
    remove_column :order_products, :nett_price, :decimal
  end
end
