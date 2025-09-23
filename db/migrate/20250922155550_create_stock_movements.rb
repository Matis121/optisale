class CreateStockMovements < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_movements do |t|
      t.references :product, null: false, foreign_key: true
      t.references :warehouse, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :movement_type, null: false
      t.integer :quantity, null: false
      t.integer :stock_before, null: false
      t.integer :stock_after, null: false
      t.references :reference, polymorphic: true, null: true
      t.text :notes
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :stock_movements, [ :product_id, :warehouse_id ]
    add_index :stock_movements, [ :reference_type, :reference_id ]
    add_index :stock_movements, :occurred_at
    add_index :stock_movements, :movement_type
  end
end
