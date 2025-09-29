# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
#
#

# Creating sample user
user = User.find_or_create_by!(email: "test@example.com")

puts "Utworzono użytkownika: #{user.email}"

# Creating catalog for user
catalog = user.catalogs.find_or_create_by!(name: "Domyślny katalog")
puts "Utworzono katalog: #{catalog.name}"

# Tworzenie magazynu dla katalogu
warehouse = catalog.warehouses.find_or_create_by!(name: "Magazyn główny", default: true)
puts "Utworzono magazyn: #{warehouse.name}"

# Tworzenie grupy cenowej dla katalogu
price_group = catalog.price_groups.find_or_create_by!(name: "Domyślna grupa cenowa", default: true)
puts "Utworzono grupę cenową: #{price_group.name}"

# Creating sample products
40.times do |i|
  product = catalog.products.find_or_create_by!(
    name: "Produkt #{i + 1}",
    sku: "SKU#{i + 1}",
    tax_rate: 23
  )

  # Creating stock for product in warehouse
  ProductStock.find_or_create_by!(
    product: product,
    warehouse: warehouse,
    quantity: rand(1..50)
  )

  ProductPrice.find_or_create_by!(
    product: product,
    price_group: price_group,
    gross_price: rand(10..100),
    currency: "PLN"
  )

  puts "Utworzono produkt: #{product.name} z ilością w magazynie: #{product.product_stocks.last.quantity}"
end

puts "Seedowanie zakończone pomyślnie."
