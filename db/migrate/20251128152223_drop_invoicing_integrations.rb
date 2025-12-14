class DropInvoicingIntegrations < ActiveRecord::Migration[8.0]
  def change
    drop_table :invoicing_integrations
  end
end
