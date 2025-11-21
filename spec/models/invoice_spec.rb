require 'rails_helper'

RSpec.describe Invoice, type: :model do
  # Testy asocjacji
  describe 'associations' do
    it { should belong_to(:account) }
    it { should belong_to(:order) }
    it { should have_many(:invoice_items).dependent(:destroy) }
  end

  # Testy walidacji
  describe 'validations' do
    let(:account) { FactoryBot.create(:account) }
    subject { Invoice.new(account: account) }

    it { should validate_presence_of(:total_price_brutto) }
    it { should validate_numericality_of(:total_price_brutto).is_greater_than_or_equal_to(0) }

    it { should validate_presence_of(:total_price_netto) }
    it { should validate_numericality_of(:total_price_netto).is_greater_than_or_equal_to(0) }

    it { should validate_presence_of(:currency) }
    it { should validate_length_of(:currency).is_at_most(3) }

    it { should validate_presence_of(:payment_method) }
    it { should validate_length_of(:payment_method).is_at_most(100) }

    it { should validate_presence_of(:date_add) }
    it { should validate_presence_of(:date_sell) }

    it { should validate_presence_of(:invoice_number) }
    it { should validate_length_of(:invoice_number).is_at_most(30) }

    it { should validate_presence_of(:invoice_fullname) }
    it { should validate_length_of(:invoice_fullname).is_at_most(100) }

    it { should validate_presence_of(:invoice_street) }
    it { should validate_length_of(:invoice_street).is_at_most(100) }

    it { should validate_presence_of(:invoice_city) }
    it { should validate_length_of(:invoice_city).is_at_most(100) }

    it { should validate_presence_of(:invoice_postcode) }
    it { should validate_length_of(:invoice_postcode).is_at_most(100) }

    it { should validate_presence_of(:invoice_country) }
    it { should validate_length_of(:invoice_country).is_at_most(50) }

    it { should validate_presence_of(:invoice_company) }
    it { should validate_length_of(:invoice_company).is_at_most(100) }

    it { should validate_presence_of(:invoice_nip) }
    it { should validate_length_of(:invoice_nip).is_at_most(100) }

    it { should validate_length_of(:external_invoice_number).is_at_most(30) }
    it { should validate_length_of(:issuer).is_at_most(100) }
    it { should validate_length_of(:seller).is_at_most(250) }
    it { should validate_length_of(:additional_info).is_at_most(500) }

    it 'validates uniqueness of order_id scoped to account_id' do
      account = FactoryBot.create(:account)
      order = FactoryBot.create(:order, account: account)
      FactoryBot.create(:invoice, account: account, order: order)

      duplicate_invoice = FactoryBot.build(:invoice, account: account, order: order)
      expect(duplicate_invoice).not_to be_valid
      expect(duplicate_invoice.errors[:order_id]).to be_present
    end
  end

  # Testy callbacków
  describe 'callbacks' do
    context 'before_validation :populate_from_order_snapshot' do
      let(:account) { FactoryBot.create(:account) }
      let(:customer) { FactoryBot.create(:customer) }
      let(:order_status) { account.order_statuses.first }
      let(:order) do
        FactoryBot.create(:order, account: account, customer: customer, order_status: order_status).tap do |o|
          invoice_address = o.addresses.invoice.first
          invoice_address.update(
            fullname: 'Jan Kowalski',
            company_name: 'Test Company',
            street: 'Test Street 123',
            city: 'Warsaw',
            postcode: '00-001',
            country: 'PL',
            nip: '1234567890'
          )
        end
      end

      it 'populates invoice data from order snapshot on new record' do
        invoice = Invoice.new(account: account, order: order)
        invoice.valid?

        expect(invoice.invoice_fullname).to eq('Jan Kowalski')
        expect(invoice.invoice_company).to eq('Test Company')
        expect(invoice.invoice_street).to eq('Test Street 123')
        expect(invoice.invoice_city).to eq('Warsaw')
        expect(invoice.invoice_postcode).to eq('00-001')
        expect(invoice.invoice_country).to eq('PL')
        expect(invoice.invoice_nip).to eq('1234567890')
      end

      it 'does not overwrite existing values' do
        invoice = Invoice.new(
          account: account,
          order: order,
          invoice_fullname: 'Existing Name'
        )
        invoice.valid?

        expect(invoice.invoice_fullname).to eq('Existing Name')
      end

      it 'does not populate when order is not present' do
        invoice = Invoice.new(account: account)
        invoice.valid?

        expect(invoice.invoice_fullname).to be_nil
      end

      it 'does not populate on existing record' do
        invoice = FactoryBot.create(:invoice, account: account, order: order)
        original_fullname = invoice.invoice_fullname

        order.addresses.invoice.first.update(fullname: 'Changed Name')
        invoice.valid?

        expect(invoice.invoice_fullname).to eq(original_fullname)
      end
    end

    context 'after_create :snapshot_invoice_items' do
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

      it 'creates invoice items from order products' do
        invoice = FactoryBot.create(:invoice, account: account, order: order)

        expect(invoice.invoice_items.count).to eq(2)
        expect(invoice.invoice_items.pluck(:name)).to contain_exactly('Product 1', 'Product 2')
      end
    end
  end

  # Testy metod instancji

  describe '#recalculate_totals' do
    let(:account) { FactoryBot.create(:account) }
    let(:order) { FactoryBot.create(:order, account: account) }
    let(:invoice) { FactoryBot.create(:invoice, account: account, order: order) }

    before do
      # Clear invoice_items created by callback
      invoice.invoice_items.destroy_all
      FactoryBot.create(:invoice_item, invoice: invoice, price_brutto: 100.0, price_netto: 81.30, quantity: 2)
      FactoryBot.create(:invoice_item, invoice: invoice, price_brutto: 50.0, price_netto: 46.30, quantity: 1)
    end

    it 'recalculates total_price_brutto and total_price_netto from invoice items' do
      invoice.update_columns(total_price_brutto: 0, total_price_netto: 0)
      invoice.invoice_items.reload # Reload association to see new items
      invoice.recalculate_totals
      invoice.reload

      expect(invoice.total_price_brutto).to eq(250.0) # (100 * 2) + (50 * 1)
      expect(invoice.total_price_netto).to eq(208.90) # (81.30 * 2) + (46.30 * 1)
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
    let(:invoice) { FactoryBot.create(:invoice, account: account, order: order) }

    it 'destroys existing invoice items and recreates from order' do
      # Invoice already has invoice_items from callback (2 items)
      # Add one more to test that restore destroys all and recreates from order
      invoice.invoice_items.create!(name: 'Old Product', price_brutto: 10.0, price_netto: 8.13, tax_rate: 23.0, quantity: 1)
      initial_count = invoice.invoice_items.count

      expect {
        result = invoice.restore_products_from_order
        expect(result).to be true
      }.to change { invoice.invoice_items.count }.from(initial_count).to(2)

      expect(invoice.invoice_items.pluck(:name)).to contain_exactly('Product 1', 'Product 2')
    end

    it 'recalculates totals after restoring' do
      invoice.invoice_items.destroy_all
      invoice.update_columns(total_price_brutto: 0, total_price_netto: 0)

      invoice.restore_products_from_order
      invoice.reload

      expect(invoice.total_price_brutto).to be > 0
    end

    it 'returns false when order is not present' do
      invoice.order = nil
      expect(invoice.restore_products_from_order).to be false
    end
  end

  describe '#restore_customer_data_from_order' do
    let(:account) { FactoryBot.create(:account) }
    let(:customer) { FactoryBot.create(:customer) }
    let(:order_status) { account.order_statuses.first }
      let(:order) do
        FactoryBot.create(:order, account: account, customer: customer, order_status: order_status).tap do |o|
          invoice_address = o.addresses.invoice.first
          invoice_address.update(
            fullname: 'Jan Kowalski',
            company_name: 'Test Company',
            street: 'Test Street 123',
            city: 'Warsaw',
            postcode: '00-001',
            country: 'PL',
            nip: '1234567890'
          )
        end
      end
    let(:invoice) { FactoryBot.create(:invoice, account: account, order: order, invoice_fullname: 'Old Name') }

    it 'restores customer data from order snapshot' do
      invoice.restore_customer_data_from_order
      invoice.reload

      expect(invoice.invoice_fullname).to eq('Jan Kowalski')
      expect(invoice.invoice_company).to eq('Test Company')
      expect(invoice.invoice_street).to eq('Test Street 123')
    end

    it 'returns false when order is not present' do
      invoice.order = nil
      expect(invoice.restore_customer_data_from_order).to be false
    end
  end

  # Testy usuwania (dependent destroy)
  describe 'dependent destroy' do
    let(:account) { FactoryBot.create(:account) }
    let(:order) { FactoryBot.create(:order, account: account) }
    let!(:invoice) { FactoryBot.create(:invoice, account: account, order: order) }

    before do
      # Clear invoice_items created by callback
      invoice.invoice_items.destroy_all
      FactoryBot.create(:invoice_item, invoice: invoice)
      FactoryBot.create(:invoice_item, invoice: invoice)
    end

    it 'destroys all associated invoice_items when invoice is destroyed' do
      initial_count = invoice.invoice_items.count
      expect(initial_count).to eq(2)

      expect {
        invoice.reload # Reload to ensure fresh association
        invoice.destroy
      }.to change { InvoiceItem.count }.by(-initial_count)
    end
  end

  # Test factory
  describe 'factory' do
    it 'has a valid factory' do
      invoice = FactoryBot.build(:invoice)
      expect(invoice).to be_valid
    end
  end
end
