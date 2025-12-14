FactoryBot.define do
  factory :account_integration do
    account { nil }
    integration { nil }
    name { "MyString" }
    credentials { "MyText" }
    settings { "" }
    status { "MyString" }
    error_message { "MyText" }
  end
end
