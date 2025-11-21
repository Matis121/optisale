require 'rails_helper'

RSpec.describe ReceiptItem, type: :model do
  # Testy asocjacji
  describe 'associations' do
    it { should belong_to(:receipt) }
  end

  # Testy walidacji
  describe 'validations' do
    subject { FactoryBot.build(:receipt_item) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(200) }

    it { should validate_length_of(:sku).is_at_most(50) }
    it { should validate_length_of(:ean).is_at_most(32) }

    it { should validate_presence_of(:price_brutto) }
    it { should validate_numericality_of(:price_brutto).is_greater_than_or_equal_to(0) }

    it { should validate_presence_of(:tax_rate) }
    it { should validate_numericality_of(:tax_rate).is_greater_than_or_equal_to(0) }

    it { should validate_presence_of(:quantity) }
    it { should validate_numericality_of(:quantity).is_greater_than_or_equal_to(0) }

    context 'when name is too long' do
      it 'is invalid' do
        receipt_item = FactoryBot.build(:receipt_item, name: 'a' * 201)
        expect(receipt_item).not_to be_valid
        expect(receipt_item.errors[:name]).to be_present
      end
    end

    context 'when sku is too long' do
      it 'is invalid' do
        receipt_item = FactoryBot.build(:receipt_item, sku: 'a' * 51)
        expect(receipt_item).not_to be_valid
        expect(receipt_item.errors[:sku]).to be_present
      end
    end

    context 'when ean is too long' do
      it 'is invalid' do
        receipt_item = FactoryBot.build(:receipt_item, ean: 'a' * 33)
        expect(receipt_item).not_to be_valid
        expect(receipt_item.errors[:ean]).to be_present
      end
    end

    context 'when price_brutto is negative' do
      it 'is invalid' do
        receipt_item = FactoryBot.build(:receipt_item, price_brutto: -1)
        expect(receipt_item).not_to be_valid
        expect(receipt_item.errors[:price_brutto]).to be_present
      end
    end

    context 'when tax_rate is negative' do
      it 'is invalid' do
        receipt_item = FactoryBot.build(:receipt_item, tax_rate: -1)
        expect(receipt_item).not_to be_valid
        expect(receipt_item.errors[:tax_rate]).to be_present
      end
    end

    context 'when quantity is negative' do
      it 'is invalid' do
        receipt_item = FactoryBot.build(:receipt_item, quantity: -1)
        expect(receipt_item).not_to be_valid
        expect(receipt_item.errors[:quantity]).to be_present
      end
    end

    context 'when all fields are valid' do
      it 'is valid' do
        receipt_item = FactoryBot.build(
          :receipt_item,
          name: 'Test Product',
          sku: 'SKU123',
          ean: '1234567890123',
          price_brutto: 100.0,
          tax_rate: 23.0,
          quantity: 2
        )
        expect(receipt_item).to be_valid
      end
    end

    context 'when optional fields are nil' do
      it 'is valid' do
        receipt_item = FactoryBot.build(
          :receipt_item,
          name: 'Test Product',
          sku: nil,
          ean: nil,
          price_brutto: 100.0,
          tax_rate: 23.0,
          quantity: 1
        )
        expect(receipt_item).to be_valid
      end
    end
  end

  # Test factory
  describe 'factory' do
    it 'has a valid factory' do
      receipt_item = FactoryBot.build(:receipt_item)
      expect(receipt_item).to be_valid
    end
  end
end
