FactoryBot.define do
  factory :receipt do
    association :account
    association :order
    receipt_number { "PA/1/#{Time.current.month}/#{Time.current.year}" }
    year { Time.current.year }
    month { Time.current.month }
    sub_id { 1 }
    date_add { Time.current }
    payment_method { "Gotówka" }
    nip { rand(1000000000..9999999999).to_s }
    currency { "PLN" }
    total_price_brutto { 100.0 }
    status { "success" }
  end
end
