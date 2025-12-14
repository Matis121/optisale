FactoryBot.define do
  factory :integration do
    name { "MyString" }
    key { "MyString" }
    integration_type { "MyString" }
    multiple_allowed { false }
    enabled { false }
    beta { false }
  end
end
