class CreateAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses do |t|
      t.references :order, null: false, foreign_key: true
      t.integer :kind, null: false
      t.string :fullname
      t.string :company_name
      t.string :street
      t.string :postcode
      t.string :city
      t.string :country
      t.string :country_code

      t.timestamps
    end
  end
end
