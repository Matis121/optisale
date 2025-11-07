require 'rails_helper'

RSpec.describe User, type: :model do
  # Testy asocjacji
  describe 'associations' do
    it { should belong_to(:account).optional }
  end

  # Testy walidacji
  describe 'validations' do
    subject { FactoryBot.create(:user) }

    it { should validate_presence_of(:role) }
    it { should validate_inclusion_of(:role).in_array(%w[owner employee]) }

    context 'when role is owner' do
      it 'is valid without account_id on new record' do
        user = FactoryBot.build(:user, role: 'owner', account_id: nil, account_name: 'Test Company', account_nip: '1234567890')
        expect(user).to be_valid
      end
    end

    context 'when role is employee' do
      it 'requires account_id' do
        account = FactoryBot.create(:account)
        user = FactoryBot.build(:user, :employee, account: account)
        expect(user).to be_valid
      end

      it 'is invalid without account_id' do
        user = User.new(email: 'test@example.com', password: 'password123', password_confirmation: 'password123', role: 'employee')
        expect(user).not_to be_valid
        expect(user.errors[:account_id]).to be_present
      end
    end
  end

  # Testy callbacku before_validation dla owner
  describe 'before_validation callback' do
    context 'when user is owner' do
      it 'builds account from attributes' do
        user = FactoryBot.build(:user, role: 'owner', account_name: 'Test Company', account_nip: '1234567890')
        user.valid?
        expect(user.account).not_to be_nil
        expect(user.account.name).to eq('Test Company')
        expect(user.account.nip).to eq('1234567890')
      end

      it 'creates account when user is created' do
        expect {
          FactoryBot.create(:user, role: 'owner', account_name: 'Test Company', account_nip: '1234567890')
        }.to change { Account.count }.by(1)
      end
    end

    context 'when user is employee' do
      it 'does not build account from attributes' do
        account = FactoryBot.create(:account)
        user = FactoryBot.build(:user, :employee, account: account, account_name: 'Should Not Build', account_nip: '9999999999')
        user.valid?
        expect(user.account).to eq(account)
        expect(user.account.name).not_to eq('Should Not Build')
      end
    end
  end

  # Testy metody delegującej
  describe '#default_order_status' do
    it 'delegates to account' do
      user = FactoryBot.create(:user)
      expect(user.default_order_status).to eq(user.account.default_order_status)
    end

    it 'returns nil when user has no account' do
      user = User.new(email: 'test@example.com', password: 'password', password_confirmation: 'password', role: 'employee')
      expect(user.default_order_status).to be_nil
    end
  end

  # Test factory
  describe 'factory' do
    it 'has a valid factory' do
      user = FactoryBot.build(:user)
      expect(user).to be_valid
    end
  end
end