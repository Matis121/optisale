class CreateIntegrations < ActiveRecord::Migration[8.0]
  def change
    create_table :integrations do |t|
      t.string :name
      t.string :key
      t.string :integration_type
      t.boolean :multiple_allowed
      t.boolean :enabled
      t.boolean :beta

      t.timestamps
    end
  end
end
