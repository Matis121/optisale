require 'rails_helper'

RSpec.describe User, type: :model do
  # Testy walidacji
  describe 'validations' do
    subject { FactoryBot.build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:password) }
    it { should validate_length_of(:password).is_at_least(2) }
    it { should validate_presence_of(:password_confirmation) }
    it { should validate_length_of(:password_confirmation).is_at_least(2) }

    context 'when email is valid' do
      it 'accepts valid email addresses' do
        valid_emails = 3.times.map { Faker::Internet.unique.email }
        valid_emails.each do |email|
          user = FactoryBot.build(:user, email: email)
          expect(user).to be_valid
        end
      end
    end

    context 'when email is invalid' do
      it 'rejects invalid email addresses' do
        invalid_emails = [ 'invalid', '@example.com', 'user@', 'user @example.com' ]
        invalid_emails.each do |email|
          user = FactoryBot.build(:user, email: email)
          expect(user).not_to be_valid
        end
      end
    end

    context 'when password is too short' do
      it 'is invalid' do
        user = FactoryBot.build(:user, password: 'a', password_confirmation: 'a')
        expect(user).not_to be_valid
      end
    end

    context 'when passwords do not match' do
      it 'is invalid' do
        user = FactoryBot.build(:user, password: 'password123', password_confirmation: 'different')
        expect(user).not_to be_valid
      end
    end
  end

  # Testy callbacku after_create
  describe 'after_create callback' do
    let(:user) { FactoryBot.create(:user) }

    it 'creates default catalog' do
      expect(user.catalogs.count).to eq(1)
      expect(user.catalogs.first.name).to eq('Domyślny')
      expect(user.catalogs.first.default).to be true
    end

    it 'creates default warehouse' do
      expect(user.warehouses.count).to eq(1)
      expect(user.warehouses.first.name).to eq('Domyślny')
      expect(user.warehouses.first.default).to be true
    end

    it 'creates default price group' do
      expect(user.price_groups.count).to eq(1)
      expect(user.price_groups.first.name).to eq('Podstawowa')
      expect(user.price_groups.first.default).to be true
    end

    it 'creates 4 default order statuses' do
      expect(user.order_statuses.count).to eq(4)
    end

    it 'creates correct order statuses with proper names' do
      status_names = user.order_statuses.pluck(:full_name)
      expect(status_names).to contain_exactly('Nowe', 'W realizacji', 'Wysłane', 'Zakończone')
    end

    it 'marks first order status as default' do
      default_status = user.order_statuses.find_by(default: true)
      expect(default_status).not_to be_nil
      expect(default_status.full_name).to eq('Nowe')
    end

    it 'connects default catalog with warehouse and price group' do
      catalog = user.catalogs.first
      expect(catalog.warehouses).to include(user.warehouses.first)
      expect(catalog.price_groups).to include(user.price_groups.first)
    end
  end

  # Testy metod instancji
  describe '#default_order_status' do
    let(:user) { FactoryBot.create(:user) }

    context 'when default order status exists' do
      it 'returns the default order status' do
        default_status = user.order_statuses.find_by(default: true)
        expect(user.default_order_status).to eq(default_status)
        expect(user.default_order_status.full_name).to eq('Nowe')
      end
    end

    context 'when no default order status is marked' do
      before do
        user.order_statuses.update_all(default: false)
      end

      it 'returns the first order status' do
        expect(user.default_order_status).to eq(user.order_statuses.first)
      end
    end
  end

  # Testy tworzenia użytkownika
  describe 'factory' do
    it 'has a valid factory' do
      user = FactoryBot.build(:user)
      expect(user).to be_valid
    end

    it 'creates a user with unique email' do
      user1 = FactoryBot.create(:user)
      user2 = FactoryBot.create(:user)
      expect(user1.email).not_to eq(user2.email)
    end

    it 'creates a persisted user' do
      user = FactoryBot.create(:user)
      expect(user).to be_persisted
      expect(user.id).not_to be_nil
    end
  end

  # Testy usuwania użytkownika
  describe 'dependent destroy' do
    before do
      @user = FactoryBot.create(:user)
    end
    it 'destroys associated catalogs when user is destroyed' do
      expect { @user.destroy }.to change { Catalog.count }.by(-1)
    end

    it 'destroys associated order_statuses when user is destroyed' do
      expect { @user.destroy }.to change { OrderStatus.count }.by(-4)
    end

    it 'destroys associated warehouses when user is destroyed' do
      expect { @user.destroy }.to change { Warehouse.count }.by(-1)
    end
  end
end
