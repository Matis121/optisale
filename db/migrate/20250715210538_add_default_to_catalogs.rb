class AddDefaultToCatalogs < ActiveRecord::Migration[8.0]
  def change
    add_column :catalogs, :default, :boolean
  end
end
