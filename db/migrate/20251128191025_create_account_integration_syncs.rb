class CreateAccountIntegrationSyncs < ActiveRecord::Migration[8.0]
  def change
    create_table :account_integration_syncs do |t|
      t.references :account_integration, null: false, foreign_key: true
      t.string :sync_type
      t.boolean :enabled
      t.integer :frequency_minutes
      t.string :status
      t.text :error_message
      t.datetime :last_sync_at

      t.timestamps
    end
  end
end
