class CreatePriceGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :price_groups do |t|
      t.string :name
      t.references :catalog, null: false, foreign_key: true

      t.timestamps
    end
  end
end
