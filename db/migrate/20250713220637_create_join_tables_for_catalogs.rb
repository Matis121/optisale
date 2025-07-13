class CreateJoinTablesForCatalogs < ActiveRecord::Migration[8.0]
  def change
    create_join_table :catalogs, :warehouses do |t|
      t.index :catalog_id
      t.index :warehouse_id
    end

    create_join_table :catalogs, :price_groups do |t|
      t.index :catalog_id
      t.index :price_group_id
    end
  end
end
