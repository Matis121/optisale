class CreateOrderStatus < ActiveRecord::Migration[8.0]
  def change
    create_table :order_statuses do |t|
      t.string :full_name
      t.string :short_name
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
