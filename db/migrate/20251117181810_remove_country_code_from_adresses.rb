class RemoveCountryCodeFromAdresses < ActiveRecord::Migration[8.0]
  def change
    remove_column :addresses, :country_code

    change_column :addresses, :country, :string, limit: 20
    change_column :addresses, :postcode, :string, limit: 10
    change_column :addresses, :city, :string, limit: 50
    change_column :addresses, :street, :string, limit: 100
    change_column :addresses, :fullname, :string, limit: 100
    change_column :addresses, :company_name, :string, limit: 100
  end
end
