class CreateCustomerPickupPoints < ActiveRecord::Migration[8.0]
  def change
    create_table :customer_pickup_points do |t|
      t.string :name
      t.string :point_id
      t.string :address
      t.string :city
      t.string :postcode
      t.string :country
      t.references :order, null: false, foreign_key: true

      t.timestamps
    end
  end
end
