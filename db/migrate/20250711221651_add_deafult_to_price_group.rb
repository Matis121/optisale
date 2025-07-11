class AddDeafultToPriceGroup < ActiveRecord::Migration[8.0]
  def change
    add_column :price_groups, :default, :boolean
  end
end
