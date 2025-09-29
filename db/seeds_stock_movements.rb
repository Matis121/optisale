# Seeds for testing stock movements system
puts "Creating test stock movements..."

# Find first user and products
user = User.first
if user.nil?
  puts "No users found. Please create a user first."
  exit
end

# Find first catalog and warehouse
catalog = user.catalogs.first
warehouse = user.warehouses.first

if catalog.nil? || warehouse.nil?
  puts "No catalog or warehouse found. Creating basic setup..."
  catalog ||= user.catalogs.create!(name: "Test Catalog")
  warehouse ||= user.warehouses.create!(name: "Main Warehouse", default: true)
end

# Find products or create test ones
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

# Create sample stock movements for each product
products.each_with_index do |product, index|
  puts "Creating stock movements for #{product.name}..."

  # Initial stock 100 pieces
  product.update_stock!(
    warehouse,
    100,
    user,
    movement_type: 'stock_in'
  )

  # Downward correction
  sleep(1) # To have different timestamps
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

  # Issue for order (simulation)
  sleep(1)
  product.update_stock!(
    warehouse,
    85,
    user,
    movement_type: 'order_placement'
  )

  # Goods receipt
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
