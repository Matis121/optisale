json.extract! product, :id, :name, :sku, :ean, :tax_rate, :nett_price, :gross_price, :created_at, :updated_at, :quantity
json.url product_url(product, format: :json)
