FactoryBot.define do
  factory :receipt do
    account { nil }
    order { nil }
    status { "MyString" }
    series_id { 1 }
    receipt_full_nr { "MyString" }
    year { 1 }
    month { 1 }
    sub_id { 1 }
    date_add { 1 }
    payment_method { "MyString" }
    nip { "MyString" }
    currency { "MyString" }
    total_price_brutto { "9.99" }
    external_receipt_number { "MyString" }
    external_id { "MyString" }
  end
end
