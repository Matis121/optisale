class CreateTaggings < ActiveRecord::Migration[8.0]
  def change
    create_table :taggings do |t|
      t.references :tag, null: false, foreign_key: true
      t.string :taggable_type
      t.bigint :taggable_id

      t.timestamps
    end

    add_index :taggings, [ :taggable_type, :taggable_id ]
    add_index :taggings, [ :tag_id, :taggable_type, :taggable_id ], unique: true
  end
end
