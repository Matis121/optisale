FactoryBot.define do
  factory :order do
    association :account
    association :customer
    association :order_status, factory: :order_status
    order_date { Time.current }
    currency { "PLN" }
    payment_method { "Przelew" }
    shipping_method { "Kurier" }
    shipping_cost { 10.0 }
    source { "Manual" }

    after(:create) do |order|
      # Create invoice address
      order.addresses.create!(
        kind: :invoice,
        fullname: Faker::Name.name,
        company_name: Faker::Company.name,
        street: Faker::Address.street_address,
        city: Faker::Address.city,
        postcode: Faker::Address.postcode,
        country: "PL",
        nip: rand(1000000000..9999999999).to_s
      )

      # Create delivery address
      order.addresses.create!(
        kind: :delivery,
        fullname: Faker::Name.name,
        street: Faker::Address.street_address,
        city: Faker::Address.city,
        postcode: Faker::Address.postcode,
        country: "PL"
      )

      # Create at least one order product
      order.order_products.create!(
        name: Faker::Commerce.product_name,
        sku: Faker::Alphanumeric.alphanumeric(number: 10),
        quantity: 1,
        gross_price: 100.0,
        tax_rate: 23.0
      )
    end
  end
end
