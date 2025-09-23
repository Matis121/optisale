class RemoveNotesFromStockMovements < ActiveRecord::Migration[8.0]
  def change
    remove_column :stock_movements, :notes, :text
  end
end
