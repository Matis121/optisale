class CreateAccountIntegrations < ActiveRecord::Migration[8.0]
  def change
    create_table :account_integrations do |t|
      t.references :account, null: false, foreign_key: true
      t.references :integration, null: false, foreign_key: true
      t.string :name
      t.text :encrypted_credentials
      t.jsonb :settings
      t.string :status
      t.text :error_message

      t.timestamps
    end
  end
end
