require 'rails_helper'

RSpec.describe Account, type: :model do
  # Testy asocjacji
  describe 'associations' do
    it { should have_many(:users).dependent(:destroy) }
    it { should have_many(:orders).dependent(:destroy) }
    it { should have_many(:catalogs).dependent(:delete_all) }
    it { should have_many(:products).through(:catalogs) }
    it { should have_many(:warehouses).dependent(:delete_all) }
    it { should have_many(:price_groups).dependent(:delete_all) }
    it { should have_many(:order_statuses).dependent(:delete_all) }
    it { should have_many(:order_status_groups).dependent(:destroy) }
    it { should have_many(:invoicing_integrations).dependent(:destroy) }
    it { should have_many(:invoices).dependent(:destroy) }
    it { should have_many(:stock_movements).dependent(:destroy) }
  end

  # Testy walidacji
  describe 'validations' do
    subject { FactoryBot.build(:account) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:nip) }
    
    it 'validates uniqueness of nip' do
      FactoryBot.create(:account, nip: '1234567890')
      duplicate_account = FactoryBot.build(:account, nip: '1234567890')
      expect(duplicate_account).not_to be_valid
      expect(duplicate_account.errors[:nip]).to be_present
    end

    it 'accepts valid 10 digit NIP' do
      account = FactoryBot.build(:account, nip: '1234567890')
      expect(account).to be_valid
    end

    it 'rejects invalid NIP format' do
      invalid_nips = ['123456789', '12345678901', '12345678AB', '1234567-90']
      invalid_nips.each do |nip|
        account = FactoryBot.build(:account, nip: nip)
        expect(account).not_to be_valid
        expect(account.errors[:nip]).to be_present
      end
    end
  end

  # Testy callbacku after_create
  describe 'after_create callback' do
    let(:account) { FactoryBot.create(:account) }

    it 'creates default catalog' do
      expect(account.catalogs.count).to eq(1)
      expect(account.catalogs.first.name).to eq('Domyślny')
      expect(account.catalogs.first.default).to be true
    end

    it 'creates default warehouse' do
      expect(account.warehouses.count).to eq(1)
      expect(account.warehouses.first.name).to eq('Domyślny')
      expect(account.warehouses.first.default).to be true
    end

    it 'creates default price group' do
      expect(account.price_groups.count).to eq(1)
      expect(account.price_groups.first.name).to eq('Podstawowa')
      expect(account.price_groups.first.default).to be true
    end

    it 'creates 4 default order statuses with correct names' do
      expect(account.order_statuses.count).to eq(4)
      status_names = account.order_statuses.pluck(:full_name)
      expect(status_names).to contain_exactly('Nowe', 'W realizacji', 'Wysłane', 'Zakończone')
      
      default_status = account.order_statuses.find_by(default: true)
      expect(default_status.full_name).to eq('Nowe')
    end

    it 'connects default catalog with warehouse and price group' do
      catalog = account.catalogs.first
      expect(catalog.warehouses).to include(account.warehouses.first)
      expect(catalog.price_groups).to include(account.price_groups.first)
    end
  end

  # Testy metod instancji
  describe '#default_order_status' do
    let(:account) { FactoryBot.create(:account) }

    it 'returns the default order status' do
      default_status = account.order_statuses.find_by(default: true)
      expect(account.default_order_status).to eq(default_status)
      expect(account.default_order_status.full_name).to eq('Nowe')
    end

    it 'returns first order status when no default is marked' do
      account.order_statuses.update_all(default: false)
      expect(account.default_order_status).to eq(account.order_statuses.first)
    end
  end

  describe '#owner' do
    it 'returns the owner user when present' do
      owner_user = FactoryBot.create(:user, :owner, account_nip: '9999999999')
      expect(owner_user.account.owner).to eq(owner_user)
    end

    it 'returns nil when account has no owner' do
      account = FactoryBot.create(:account)
      expect(account.owner).to be_nil
    end
  end

  # Testy usuwania konta (dependent destroy)
  describe 'dependent destroy' do
    let!(:account) { FactoryBot.create(:account) }

    it 'destroys all associated records when account is destroyed' do
      expect { account.destroy }.to change { Catalog.count }.by(-1)
        .and change { OrderStatus.count }.by(-4)
        .and change { Warehouse.count }.by(-1)
        .and change { PriceGroup.count }.by(-1)
        .and change { User.count }.by(-account.users.count)
    end
  end

  # Test factory
  describe 'factory' do
    it 'has a valid factory' do
      account = FactoryBot.build(:account)
      expect(account).to be_valid
    end
  end
end