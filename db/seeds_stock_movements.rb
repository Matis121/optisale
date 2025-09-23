# Seeds for testing stock movements system
puts "Creating test stock movements..."

# Znajdź pierwszego użytkownika i produkty
user = User.first
if user.nil?
  puts "No users found. Please create a user first."
  exit
end

# Znajdź pierwszy katalog i magazyn
catalog = user.catalogs.first
warehouse = user.warehouses.first

if catalog.nil? || warehouse.nil?
  puts "No catalog or warehouse found. Creating basic setup..."
  catalog ||= user.catalogs.create!(name: "Test Catalog")
  warehouse ||= user.warehouses.create!(name: "Main Warehouse", default: true)
end

# Znajdź produkty lub stwórz testowe
products = catalog.products.limit(3)

if products.empty?
  puts "Creating test products..."
  products = [
    catalog.products.create!(
      name: "Test Product 1",
      sku: "TEST001",
      ean: "1234567890123",
      tax_rate: 23.0
    ),
    catalog.products.create!(
      name: "Test Product 2",
      sku: "TEST002",
      ean: "1234567890124",
      tax_rate: 23.0
    ),
    catalog.products.create!(
      name: "Test Product 3",
      sku: "TEST003",
      ean: "1234567890125",
      tax_rate: 23.0
    )
  ]
end

# Stwórz przykładowe ruchy magazynowe dla każdego produktu
products.each_with_index do |product, index|
  puts "Creating stock movements for #{product.name}..."

  # Początkowy stan 100 sztuk
  product.update_stock!(
    warehouse,
    100,
    user,
    movement_type: 'stock_in'
  )

  # Korekta w dół
  sleep(1) # Żeby mieć różne czasy
  product.update_stock!(
    warehouse,
    95,
    user,
    movement_type: 'manual_adjustment'
  )

  # Uszkodzenie
  sleep(1)
  product.update_stock!(
    warehouse,
    90,
    user,
    movement_type: 'damage'
  )

  # Wydanie na zamówienie (symulacja)
  sleep(1)
  product.update_stock!(
    warehouse,
    85,
    user,
    movement_type: 'order_placement'
  )

  # Przyjęcie towaru
  sleep(1)
  product.update_stock!(
    warehouse,
    135,
    user,
    movement_type: 'stock_in'
  )
end

puts "Stock movements created successfully!"
puts "You can now test the stock history modal in the products table."
