class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name
      t.string :color
      t.string :scopes, array: true, default: []

      t.timestamps
    end

    add_index :tags, [ :account_id, :name ], unique: true
    add_index :tags, :scopes, using: :gin
  end
end
