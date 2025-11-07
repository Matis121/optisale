FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { "strongpassword123" }
    password_confirmation { "strongpassword123" }

    trait :owner do
      role { "owner" }
      account_name { Faker::Company.name }
      account_nip { rand(1000000000..9999999999).to_s }
    end

    trait :employee do
      role { "employee" }
      account { association(:account) }
    end
  end
end
