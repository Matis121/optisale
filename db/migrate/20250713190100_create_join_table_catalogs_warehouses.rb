class CreateJoinTableCatalogsWarehouses < ActiveRecord::Migration[8.0]
  def change
    create_join_table :catalogs, :warehouses do |t|
      t.index [:catalog_id, :warehouse_id]
      t.index [:warehouse_id, :catalog_id]
    end
  end
end
