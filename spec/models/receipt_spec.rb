require 'rails_helper'

RSpec.describe Receipt, type: :model do
  # Testy asocjacji
  describe 'associations' do
    it { should belong_to(:account) }
    it { should belong_to(:order) }
    it { should have_many(:receipt_items).dependent(:destroy) }
  end

  # Testy walidacji
  describe 'validations' do
    let(:account) { FactoryBot.create(:account) }
    subject { Receipt.new(account: account) }

    it { should validate_presence_of(:total_price_brutto) }
    it { should validate_numericality_of(:total_price_brutto).is_greater_than_or_equal_to(0) }

    it { should validate_presence_of(:currency) }
    it { should validate_length_of(:currency).is_at_most(3) }

    it { should validate_presence_of(:payment_method) }
    it { should validate_length_of(:payment_method).is_at_most(30) }

    it { should validate_presence_of(:date_add) }

    it { should validate_presence_of(:receipt_number) }
    it { should validate_length_of(:receipt_number).is_at_most(30) }

    it { should validate_presence_of(:year) }
    it { should validate_presence_of(:month) }
    it { should validate_presence_of(:sub_id) }

    it { should validate_length_of(:nip).is_at_most(30) }
    it { should validate_length_of(:external_receipt_number).is_at_most(30) }
    it { should validate_length_of(:external_id).is_at_most(30) }

    it 'validates uniqueness of order_id scoped to account_id' do
      account = FactoryBot.create(:account)
      order = FactoryBot.create(:order, account: account)
      FactoryBot.create(:receipt, account: account, order: order)

      duplicate_receipt = FactoryBot.build(:receipt, account: account, order: order)
      expect(duplicate_receipt).not_to be_valid
      expect(duplicate_receipt.errors[:order_id]).to be_present
    end
  end

  # Testy callbacków
  describe 'callbacks' do
    context 'before_validation :populate_from_order_snapshot' do
      let(:account) { FactoryBot.create(:account) }
      let(:customer) { FactoryBot.create(:customer) }
      let(:order_status) { account.order_statuses.first }
      let(:order) do
        FactoryBot.create(:order, account: account, customer: customer, order_status: order_status, payment_method: 'Gotówka', currency: 'PLN').tap do |o|
          invoice_address = o.addresses.invoice.first
          invoice_address.update(nip: '1234567890')
        end
      end

      it 'populates receipt data from order snapshot on new record' do
        receipt = Receipt.new(account: account, order: order)
        receipt.valid?

        expect(receipt.total_price_brutto).to eq(order.total_price)
        expect(receipt.currency).to eq('PLN')
        expect(receipt.payment_method).to eq('Gotówka')
        expect(receipt.nip).to eq('1234567890')
        expect(receipt.year).to eq(order.order_date&.year || order.created_at.year)
        expect(receipt.month).to eq(order.order_date&.month || order.created_at.month)
        expect(receipt.receipt_number).to be_present
      end

      it 'does not overwrite existing values' do
        receipt = Receipt.new(
          account: account,
          order: order,
          currency: 'USD'
        )
        receipt.valid?

        expect(receipt.currency).to eq('USD')
      end

      it 'does not populate when order is not present' do
        receipt = Receipt.new(account: account)
        receipt.valid?

        expect(receipt.total_price_brutto).to be_nil
      end

      it 'does not populate on existing record' do
        receipt = FactoryBot.create(:receipt, account: account, order: order)
        original_total = receipt.total_price_brutto

        order.order_products.first.update(gross_price: 999.99)
        receipt.valid?

        expect(receipt.total_price_brutto).to eq(original_total)
      end
    end

    context 'after_create :snapshot_receipt_items' do
      let(:account) { FactoryBot.create(:account) }
      let(:customer) { FactoryBot.create(:customer) }
      let(:order_status) { account.order_statuses.first }
      let(:order) do
        FactoryBot.create(:order, account: account, customer: customer, order_status: order_status).tap do |o|
          # Clear default order products created by factory
          o.order_products.destroy_all
          o.order_products.create!(name: 'Product 1', gross_price: 100.0, tax_rate: 23.0, quantity: 2)
          o.order_products.create!(name: 'Product 2', gross_price: 50.0, tax_rate: 8.0, quantity: 1)
        end
      end

      it 'creates receipt items from order products' do
        receipt = FactoryBot.create(:receipt, account: account, order: order)

        expect(receipt.receipt_items.count).to eq(2)
        expect(receipt.receipt_items.pluck(:name)).to contain_exactly('Product 1', 'Product 2')
      end
    end
  end

  # Testy metod instancji

  describe '#recalculate_totals' do
    let(:account) { FactoryBot.create(:account) }
    let(:order) { FactoryBot.create(:order, account: account) }
    let(:receipt) { FactoryBot.create(:receipt, account: account, order: order) }

    before do
      # Clear receipt_items created by callback
      receipt.receipt_items.destroy_all
      FactoryBot.create(:receipt_item, receipt: receipt, price_brutto: 100.0, quantity: 2)
      FactoryBot.create(:receipt_item, receipt: receipt, price_brutto: 50.0, quantity: 1)
    end

    it 'recalculates total_price_brutto from receipt items' do
      receipt.update_columns(total_price_brutto: 0)
      receipt.receipt_items.reload # Reload association to see new items
      receipt.recalculate_totals
      receipt.reload

      expect(receipt.total_price_brutto).to eq(250.0) # (100 * 2) + (50 * 1)
    end
  end

  describe '#restore_products_from_order' do
    let(:account) { FactoryBot.create(:account) }
    let(:customer) { FactoryBot.create(:customer) }
    let(:order_status) { account.order_statuses.first }
      let(:order) do
        FactoryBot.create(:order, account: account, customer: customer, order_status: order_status).tap do |o|
          # Clear default order products created by factory
          o.order_products.destroy_all
          o.order_products.create!(name: 'Product 1', gross_price: 100.0, tax_rate: 23.0, quantity: 2)
          o.order_products.create!(name: 'Product 2', gross_price: 50.0, tax_rate: 8.0, quantity: 1)
        end
      end
    let(:receipt) { FactoryBot.create(:receipt, account: account, order: order) }

    it 'destroys existing receipt items and recreates from order' do
      # Receipt already has receipt_items from callback (2 items)
      # Add one more to test that restore destroys all and recreates from order
      receipt.receipt_items.create!(name: 'Old Product', price_brutto: 10.0, tax_rate: 23.0, quantity: 1)
      initial_count = receipt.receipt_items.count

      expect {
        result = receipt.restore_products_from_order
        expect(result).to be true
      }.to change { receipt.receipt_items.count }.from(initial_count).to(2)

      expect(receipt.receipt_items.pluck(:name)).to contain_exactly('Product 1', 'Product 2')
    end

    it 'recalculates totals after restoring' do
      receipt.receipt_items.destroy_all
      receipt.update_columns(total_price_brutto: 0)

      receipt.restore_products_from_order
      receipt.reload

      expect(receipt.total_price_brutto).to be > 0
    end

    it 'returns false when order is not present' do
      receipt.order = nil
      expect(receipt.restore_products_from_order).to be false
    end
  end

  # Testy usuwania (dependent destroy)
  describe 'dependent destroy' do
    let(:account) { FactoryBot.create(:account) }
    let(:order) { FactoryBot.create(:order, account: account) }
    let!(:receipt) { FactoryBot.create(:receipt, account: account, order: order) }

    before do
      # Clear receipt_items created by callback
      receipt.receipt_items.destroy_all
      FactoryBot.create(:receipt_item, receipt: receipt)
      FactoryBot.create(:receipt_item, receipt: receipt)
    end

    it 'destroys all associated receipt_items when receipt is destroyed' do
      initial_count = receipt.receipt_items.count
      expect(initial_count).to eq(2)

      expect {
        receipt.reload # Reload to ensure fresh association
        receipt.destroy
      }.to change { ReceiptItem.count }.by(-initial_count)
    end
  end

  # Test factory
  describe 'factory' do
    it 'has a valid factory' do
      receipt = FactoryBot.build(:receipt)
      expect(receipt).to be_valid
    end
  end
end
