FactoryBot.define do
  factory :order_status do
    association :account
    full_name { Faker::Lorem.word }
    short_name { Faker::Lorem.word }
    color { "#667EEA" }
    position { 0 }
    default { false }
  end
end
