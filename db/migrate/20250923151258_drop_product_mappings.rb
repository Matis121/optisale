class DropProductMappings < ActiveRecord::Migration[8.0]
  def change
    drop_table :product_mappings do |t|
      t.bigint "product_id", null: false
      t.string "marketplace_sku"
      t.string "marketplace_ean"
      t.string "marketplace", null: false
      t.boolean "active", default: true
      t.text "additional_data"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false

      t.index [ "marketplace", "marketplace_ean" ], name: "index_product_mappings_on_marketplace_and_marketplace_ean"
      t.index [ "marketplace", "marketplace_sku" ], name: "index_product_mappings_on_marketplace_and_marketplace_sku"
      t.index [ "product_id", "marketplace" ], name: "index_product_mappings_on_product_id_and_marketplace", unique: true
      t.index [ "product_id" ], name: "index_product_mappings_on_product_id"
    end
  end
end
