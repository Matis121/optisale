class CreateCatalogs < ActiveRecord::Migration[8.0]
  def change
    create_table :catalogs do |t|
      t.string :name
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
