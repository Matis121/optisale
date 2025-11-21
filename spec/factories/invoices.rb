FactoryBot.define do
  factory :invoice do
    association :account
    association :order
    invoice_number { "FV/1/#{Time.current.month}/#{Time.current.year}" }
    invoice_fullname { Faker::Name.name }
    invoice_company { Faker::Company.name }
    invoice_nip { rand(1000000000..9999999999).to_s }
    invoice_street { Faker::Address.street_address }
    invoice_city { Faker::Address.city }
    invoice_postcode { Faker::Address.postcode }
    invoice_country { "PL" }
    sub_id { 1 }
    month { Time.current.month }
    year { Time.current.year }
    total_price_brutto { 100.0 }
    total_price_netto { 81.30 }
    currency { "PLN" }
    payment_method { "Przelew" }
    date_add { Time.current }
    date_sell { Time.current }
    status { "success" }
  end
end
