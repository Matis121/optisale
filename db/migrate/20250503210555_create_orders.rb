class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :source
      t.string :status
      t.datetime :order_date
      t.decimal :total_amount
      t.string :currency

      t.timestamps
    end
  end
end
