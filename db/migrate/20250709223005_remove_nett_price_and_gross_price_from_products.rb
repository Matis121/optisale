class RemoveNettPriceAndGrossPriceFromProducts < ActiveRecord::Migration[8.0]
  def change
    remove_column :products, :nett_price, :decimal
    remove_column :products, :gross_price, :decimal
  end
end
