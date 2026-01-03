FactoryBot.define do
  factory :tagging do
    tag { nil }
    taggable_type { "MyString" }
    taggable_id { "" }
  end
end
