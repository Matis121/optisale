FactoryBot.define do
  factory :account_integration_sync do
    account_integration { nil }
    sync_type { "MyString" }
    enabled { false }
    frequency_minutes { 1 }
    status { "MyString" }
    error_message { "MyText" }
    last_sync_at { "2025-11-28 20:10:25" }
  end
end
