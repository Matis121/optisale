class RenameEncryptedCredentialsToCredentials < ActiveRecord::Migration[8.0]
  def change
    rename_column :account_integrations, :encrypted_credentials, :credentials
  end
end