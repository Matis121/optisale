class CreateJoinTableCatalogPriceGroups < ActiveRecord::Migration[8.0]
  def change
    create_join_table :catalogs, :PriceGroups do |t|
      t.index [:catalog_id, :price_group_id]
      t.index [:price_group_id, :catalog_id]
    end
  end
end
