class AddRefferenceToPriceGroups < ActiveRecord::Migration[8.0]
  def change
    add_reference :price_groups, :user, null: true, foreign_key: true
  end
end
