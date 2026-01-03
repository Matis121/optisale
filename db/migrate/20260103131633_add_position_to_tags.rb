class AddPositionToTags < ActiveRecord::Migration[8.0]
  def change
    add_column :tags, :position, :integer
  end
end
