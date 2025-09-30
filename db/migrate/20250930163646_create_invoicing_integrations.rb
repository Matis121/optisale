class CreateInvoicingIntegrations < ActiveRecord::Migration[8.0]
  def change
    create_table :invoicing_integrations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :name, null: false
      t.boolean :active, default: false
      t.text :encrypted_credentials
      t.text :configuration
      t.string :status, default: 'inactive'
      t.datetime :last_sync_at
      t.text :error_message

      t.timestamps
    end

    add_index :invoicing_integrations, [ :user_id, :provider ]
    add_index :invoicing_integrations, :active
    add_index :invoicing_integrations, :status
  end
end
