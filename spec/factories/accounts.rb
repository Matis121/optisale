FactoryBot.define do
  factory :account do
    name { Faker::Company.name }
    nip { rand(1000000000..9999999999).to_s }
    
    after(:create) do |account|
      create(:user, :employee, account: account) unless account.users.any?
    end
  end
end
