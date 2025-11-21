FactoryBot.define do
  factory :receipt_item do
    receipt { nil }
    name { "MyString" }
    sku { "MyString" }
    ean { "MyString" }
    price_brutto { "9.99" }
    tax_rate { "9.99" }
    quantity { 1 }
  end
end
