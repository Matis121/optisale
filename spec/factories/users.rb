FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { "password123" }
    password_confirmation { "password123" }
    role { "owner" }
    account_name { Faker::Company.name }
    account_nip { "1234567890" }

    trait :employee do
      role { "employee" }
      account { create(:account) }
      account_name { nil }
      account_nip { nil }
    end

    trait :owner do
      role { "owner" }
      account_name { Faker::Company.name }
      account_nip { rand(1000000000..9999999999).to_s }
    end
  end
end
