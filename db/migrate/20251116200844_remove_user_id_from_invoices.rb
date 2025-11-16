class RemoveUserIdFromInvoices < ActiveRecord::Migration[8.0]
  def change
    remove_column :invoices, :user_id, :bigint
  end
end
