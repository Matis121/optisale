class StockMovement < ApplicationRecord
  belongs_to :account
  belongs_to :product
  belongs_to :warehouse
  belongs_to :user
  belongs_to :reference, polymorphic: true, optional: true

  MOVEMENT_TYPES = %w[
    order_placement
    manual_adjustment
    stock_in
    stock_out
    return
    damage
    transfer_in
    transfer_out
    correction
    product_creation
  ].freeze

  validates :movement_type, presence: true, inclusion: { in: MOVEMENT_TYPES }
  validates :quantity, presence: true
  validates :stock_before, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :stock_after, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :occurred_at, presence: true

  scope :for_product, ->(product) { where(product: product) }
  scope :for_warehouse, ->(warehouse) { where(warehouse: warehouse) }
  scope :for_product_and_warehouse, ->(product, warehouse) { where(product: product, warehouse: warehouse) }
  scope :recent, -> { order(occurred_at: :desc) }
  scope :by_type, ->(type) { where(movement_type: type) }

  def self.ransackable_attributes(auth_object = nil)
    %w[movement_type quantity stock_before stock_after occurred_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[product warehouse user reference]
  end

  def stock_increase?
    quantity > 0
  end

  def stock_decrease?
    quantity < 0
  end

  def display_type
    case movement_type
    when "order_placement"
      "Zamówienie"
    when "manual_adjustment"
      "Korekta manualna"
    when "stock_in"
      "Przyjęcie towaru"
    when "stock_out"
      "Wydanie towaru"
    when "return"
      "Zwrot"
    when "damage"
      "Uszkodzenie"
    when "transfer_in"
      "Transfer wewnętrzny (wejście)"
    when "transfer_out"
      "Transfer wewnętrzny (wyjście)"
    when "correction"
      "Korekta"
    when "product_creation"
      "Utworzenie produktu"
    else
      movement_type.humanize
    end
  end
end
