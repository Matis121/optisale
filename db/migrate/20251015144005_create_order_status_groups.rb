class CreateOrderStatusGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :order_status_groups do |t|
      t.string :name
      t.integer :position
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
