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

ActiveRecord::Schema[8.0].define(version: 2025_07_24_225114) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "default"
    t.index ["user_id"], name: "index_catalogs_on_user_id"
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

  create_table "order_products", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id"
    t.string "name"
    t.string "sku"
    t.string "ean"
    t.integer "quantity"
    t.decimal "gross_price", precision: 10, scale: 2, default: "0.0"
    t.decimal "nett_price", precision: 10, scale: 2, default: "0.0"
    t.decimal "tax_rate", precision: 3, scale: 1, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_products_on_order_id"
    t.index ["product_id"], name: "index_order_products_on_product_id"
  end

  create_table "order_statuses", force: :cascade do |t|
    t.string "full_name"
    t.string "short_name"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_order_statuses_on_user_id"
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
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "price_groups", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "default"
    t.bigint "user_id"
    t.index ["user_id"], name: "index_price_groups_on_user_id"
  end

  create_table "product_prices", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "price_group_id", null: false
    t.decimal "nett_price"
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

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "warehouses", force: :cascade do |t|
    t.string "name"
    t.boolean "default"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_warehouses_on_user_id"
  end

  add_foreign_key "addresses", "orders"
  add_foreign_key "catalogs", "users"
  add_foreign_key "customer_pickup_points", "orders"
  add_foreign_key "order_products", "orders"
  add_foreign_key "order_products", "products"
  add_foreign_key "order_statuses", "users"
  add_foreign_key "orders", "customers"
  add_foreign_key "orders", "users"
  add_foreign_key "price_groups", "users"
  add_foreign_key "product_prices", "price_groups"
  add_foreign_key "product_prices", "products"
  add_foreign_key "product_stocks", "products"
  add_foreign_key "product_stocks", "warehouses"
  add_foreign_key "products", "catalogs"
  add_foreign_key "warehouses", "users"
end
