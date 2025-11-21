FactoryBot.define do
  factory :invoice_item do
    association :invoice
    name { "Test Product" }
    sku { "SKU123" }
    ean { "1234567890123" }
    price_brutto { 100.0 }
    price_netto { 81.30 }
    tax_rate { 23.0 }
    quantity { 1 }
  end
end
