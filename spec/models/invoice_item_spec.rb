require 'rails_helper'

RSpec.describe InvoiceItem, type: :model do
  # Testy asocjacji
  describe 'associations' do
    it { should belong_to(:invoice) }
  end

  # Testy walidacji
  describe 'validations' do
    subject { FactoryBot.build(:invoice_item) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(200) }

    it { should validate_length_of(:sku).is_at_most(50) }
    it { should validate_length_of(:ean).is_at_most(32) }

    it { should validate_presence_of(:price_brutto) }
    it { should validate_numericality_of(:price_brutto).is_greater_than_or_equal_to(0) }

    it { should validate_presence_of(:price_netto) }
    it { should validate_numericality_of(:price_netto).is_greater_than_or_equal_to(0) }

    it { should validate_presence_of(:tax_rate) }
    it { should validate_numericality_of(:tax_rate).is_greater_than_or_equal_to(0) }

    it { should validate_presence_of(:quantity) }
    it { should validate_numericality_of(:quantity).is_greater_than_or_equal_to(0) }

    context 'when name is too long' do
      it 'is invalid' do
        invoice_item = FactoryBot.build(:invoice_item, name: 'a' * 201)
        expect(invoice_item).not_to be_valid
        expect(invoice_item.errors[:name]).to be_present
      end
    end

    context 'when sku is too long' do
      it 'is invalid' do
        invoice_item = FactoryBot.build(:invoice_item, sku: 'a' * 51)
        expect(invoice_item).not_to be_valid
        expect(invoice_item.errors[:sku]).to be_present
      end
    end

    context 'when ean is too long' do
      it 'is invalid' do
        invoice_item = FactoryBot.build(:invoice_item, ean: 'a' * 33)
        expect(invoice_item).not_to be_valid
        expect(invoice_item.errors[:ean]).to be_present
      end
    end

    context 'when price_brutto is negative' do
      it 'is invalid' do
        invoice_item = FactoryBot.build(:invoice_item, price_brutto: -1)
        expect(invoice_item).not_to be_valid
        expect(invoice_item.errors[:price_brutto]).to be_present
      end
    end

    context 'when price_netto is negative' do
      it 'is invalid' do
        invoice_item = FactoryBot.build(:invoice_item, price_netto: -1)
        expect(invoice_item).not_to be_valid
        expect(invoice_item.errors[:price_netto]).to be_present
      end
    end

    context 'when tax_rate is negative' do
      it 'is invalid' do
        invoice_item = FactoryBot.build(:invoice_item, tax_rate: -1)
        expect(invoice_item).not_to be_valid
        expect(invoice_item.errors[:tax_rate]).to be_present
      end
    end

    context 'when quantity is negative' do
      it 'is invalid' do
        invoice_item = FactoryBot.build(:invoice_item, quantity: -1)
        expect(invoice_item).not_to be_valid
        expect(invoice_item.errors[:quantity]).to be_present
      end
    end

    context 'when all fields are valid' do
      it 'is valid' do
        invoice_item = FactoryBot.build(
          :invoice_item,
          name: 'Test Product',
          sku: 'SKU123',
          ean: '1234567890123',
          price_brutto: 100.0,
          price_netto: 81.30,
          tax_rate: 23.0,
          quantity: 2
        )
        expect(invoice_item).to be_valid
      end
    end

    context 'when optional fields are nil' do
      it 'is valid' do
        invoice_item = FactoryBot.build(
          :invoice_item,
          name: 'Test Product',
          sku: nil,
          ean: nil,
          price_brutto: 100.0,
          price_netto: 81.30,
          tax_rate: 23.0,
          quantity: 1
        )
        expect(invoice_item).to be_valid
      end
    end
  end

  # Test factory
  describe 'factory' do
    it 'has a valid factory' do
      invoice_item = FactoryBot.build(:invoice_item)
      expect(invoice_item).to be_valid
    end
  end
end
