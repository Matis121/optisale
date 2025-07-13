class RemoveCatalogIdFromWarehousesAndPriceGroups < ActiveRecord::Migration[8.0]
  def change
    remove_reference :warehouses, :catalog, index: true
    remove_reference :price_groups, :catalog, index: true
  end
end
