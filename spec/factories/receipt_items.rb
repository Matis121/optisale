FactoryBot.define do
  factory :receipt_item do
    association :receipt
    name { "Test Product" }
    sku { "SKU123" }
    ean { "1234567890123" }
    price_brutto { 100.0 }
    tax_rate { 23.0 }
    quantity { 1 }
  end
end
