class DropInventoryTransactions < ActiveRecord::Migration[8.0]
  def change
    drop_table :inventory_transactions do |t|
      t.bigint "product_id", null: false
      t.bigint "warehouse_id", null: false
      t.string "transaction_type"
      t.integer "quantity"
      t.string "reference_type"
      t.integer "reference_id"
      t.bigint "user_id", null: false
      t.text "notes"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false

      t.index [ "product_id" ], name: "index_inventory_transactions_on_product_id"
      t.index [ "user_id" ], name: "index_inventory_transactions_on_user_id"
      t.index [ "warehouse_id" ], name: "index_inventory_transactions_on_warehouse_id"
    end
  end
end
