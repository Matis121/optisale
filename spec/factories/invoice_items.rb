FactoryBot.define do
  factory :invoice_item do
    invoice { nil }
    name { "MyString" }
    sku { "MyString" }
    ean { "MyString" }
    price_brutto { "9.99" }
    price_netto { "9.99" }
    tax_rate { "9.99" }
  end
end
