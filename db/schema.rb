# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_11_07_200325) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nip"
  end

  create_table "addresses", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.integer "kind", null: false
    t.string "fullname"
    t.string "company_name"
    t.string "street"
    t.string "postcode"
    t.string "city"
    t.string "country"
    t.string "country_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_addresses_on_order_id"
  end

  create_table "catalogs", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "default"
    t.bigint "account_id"
    t.index ["account_id"], name: "index_catalogs_on_account_id"
  end

  create_table "catalogs_price_groups", id: false, force: :cascade do |t|
    t.bigint "catalog_id", null: false
    t.bigint "price_group_id", null: false
    t.index ["catalog_id"], name: "index_catalogs_price_groups_on_catalog_id"
    t.index ["price_group_id"], name: "index_catalogs_price_groups_on_price_group_id"
  end

  create_table "catalogs_warehouses", id: false, force: :cascade do |t|
    t.bigint "catalog_id", null: false
    t.bigint "warehouse_id", null: false
    t.index ["catalog_id"], name: "index_catalogs_warehouses_on_catalog_id"
    t.index ["warehouse_id"], name: "index_catalogs_warehouses_on_warehouse_id"
  end

  create_table "customer_pickup_points", force: :cascade do |t|
    t.string "name"
    t.string "point_id"
    t.string "address"
    t.string "city"
    t.string "postcode"
    t.string "country"
    t.bigint "order_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_customer_pickup_points_on_order_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "login"
    t.string "email"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "order_id", null: false
    t.bigint "invoicing_integration_id", null: false
    t.string "invoice_number"
    t.string "external_id"
    t.string "status"
    t.decimal "amount"
    t.date "issue_date"
    t.date "due_date"
    t.string "external_url"
    t.text "external_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "account_id"
    t.index ["account_id"], name: "index_invoices_on_account_id"
    t.index ["invoicing_integration_id"], name: "index_invoices_on_invoicing_integration_id"
    t.index ["order_id"], name: "index_invoices_on_order_id"
    t.index ["user_id"], name: "index_invoices_on_user_id"
  end

  create_table "invoicing_integrations", force: :cascade do |t|
    t.string "provider", null: false
    t.string "name", null: false
    t.boolean "active", default: false
    t.text "encrypted_credentials"
    t.text "configuration"
    t.string "status", default: "inactive"
    t.datetime "last_sync_at"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "account_id"
    t.index ["account_id"], name: "index_invoicing_integrations_on_account_id"
    t.index ["active"], name: "index_invoicing_integrations_on_active"
    t.index ["status"], name: "index_invoicing_integrations_on_status"
  end

  create_table "order_products", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id"
    t.string "name"
    t.string "sku"
    t.string "ean"
    t.integer "quantity"
    t.decimal "gross_price", precision: 10, scale: 2, default: "0.0"
    t.decimal "tax_rate", precision: 3, scale: 1, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "warehouse_id"
    t.index ["order_id"], name: "index_order_products_on_order_id"
    t.index ["product_id"], name: "index_order_products_on_product_id"
    t.index ["warehouse_id"], name: "index_order_products_on_warehouse_id"
  end

  create_table "order_status_groups", force: :cascade do |t|
    t.string "name"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "account_id"
    t.index ["account_id"], name: "index_order_status_groups_on_account_id"
  end

  create_table "order_statuses", force: :cascade do |t|
    t.string "full_name"
    t.string "short_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", default: 0
    t.string "color", default: "#667EEA", null: false
    t.bigint "order_status_group_id"
    t.boolean "default"
    t.bigint "account_id"
    t.index ["account_id"], name: "index_order_statuses_on_account_id"
    t.index ["order_status_group_id"], name: "index_order_statuses_on_order_status_group_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "source"
    t.datetime "order_date"
    t.string "currency"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status_id"
    t.bigint "customer_id"
    t.string "shipping_method"
    t.decimal "shipping_cost"
    t.string "payment_method"
    t.string "extra_field_1", limit: 50
    t.string "extra_field_2", limit: 50
    t.string "admin_comments", limit: 150
    t.decimal "amount_paid", precision: 10, scale: 2, default: "0.0", null: false
    t.bigint "account_id"
    t.index ["account_id"], name: "index_orders_on_account_id"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "price_groups", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "default"
    t.bigint "account_id"
    t.index ["account_id"], name: "index_price_groups_on_account_id"
  end

  create_table "product_prices", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "price_group_id", null: false
    t.decimal "gross_price"
    t.string "currency"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["price_group_id"], name: "index_product_prices_on_price_group_id"
    t.index ["product_id"], name: "index_product_prices_on_product_id"
  end

  create_table "product_stocks", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "warehouse_id", null: false
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_stocks_on_product_id"
    t.index ["warehouse_id"], name: "index_product_stocks_on_warehouse_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.string "sku"
    t.string "ean"
    t.decimal "tax_rate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "catalog_id", null: false
    t.index ["catalog_id"], name: "index_products_on_catalog_id"
  end

  create_table "stock_movements", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "warehouse_id", null: false
    t.bigint "user_id", null: false
    t.string "movement_type", null: false
    t.integer "quantity", null: false
    t.integer "stock_before", null: false
    t.integer "stock_after", null: false
    t.string "reference_type"
    t.bigint "reference_id"
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "account_id"
    t.index ["account_id"], name: "index_stock_movements_on_account_id"
    t.index ["movement_type"], name: "index_stock_movements_on_movement_type"
    t.index ["occurred_at"], name: "index_stock_movements_on_occurred_at"
    t.index ["product_id", "warehouse_id"], name: "index_stock_movements_on_product_id_and_warehouse_id"
    t.index ["product_id"], name: "index_stock_movements_on_product_id"
    t.index ["reference_type", "reference_id"], name: "index_stock_movements_on_reference"
    t.index ["reference_type", "reference_id"], name: "index_stock_movements_on_reference_type_and_reference_id"
    t.index ["user_id"], name: "index_stock_movements_on_user_id"
    t.index ["warehouse_id"], name: "index_stock_movements_on_warehouse_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "account_id", null: false
    t.string "role", default: "owner", null: false
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "warehouses", force: :cascade do |t|
    t.string "name"
    t.boolean "default"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "account_id"
    t.index ["account_id"], name: "index_warehouses_on_account_id"
  end

  add_foreign_key "addresses", "orders"
  add_foreign_key "catalogs", "accounts"
  add_foreign_key "customer_pickup_points", "orders"
  add_foreign_key "invoices", "accounts"
  add_foreign_key "invoices", "invoicing_integrations"
  add_foreign_key "invoices", "orders"
  add_foreign_key "invoices", "users"
  add_foreign_key "invoicing_integrations", "accounts"
  add_foreign_key "order_products", "orders"
  add_foreign_key "order_products", "products"
  add_foreign_key "order_products", "warehouses"
  add_foreign_key "order_status_groups", "accounts"
  add_foreign_key "order_statuses", "accounts"
  add_foreign_key "order_statuses", "order_status_groups"
  add_foreign_key "orders", "accounts"
  add_foreign_key "orders", "customers"
  add_foreign_key "orders", "users"
  add_foreign_key "price_groups", "accounts"
  add_foreign_key "product_prices", "price_groups"
  add_foreign_key "product_prices", "products"
  add_foreign_key "product_stocks", "products"
  add_foreign_key "product_stocks", "warehouses"
  add_foreign_key "products", "catalogs"
  add_foreign_key "stock_movements", "accounts"
  add_foreign_key "stock_movements", "products"
  add_foreign_key "stock_movements", "users"
  add_foreign_key "stock_movements", "warehouses"
  add_foreign_key "users", "accounts"
  add_foreign_key "warehouses", "accounts"
end
