FactoryBot.define do
  factory :customer do
    login { Faker::Internet.username }
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.cell_phone }
  end
end
