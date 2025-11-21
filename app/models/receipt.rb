class Receipt < ApplicationRecord
  belongs_to :account
  belongs_to :order
  has_many :receipt_items, dependent: :destroy

  enum :status, {
    success: "success",
    error: "error"
  }

  before_validation :populate_from_order_snapshot, if: -> { order.present? && new_record? }
  after_create :snapshot_receipt_items

  validates :order_id, uniqueness: { scope: :account_id, message: "może mieć tylko jeden paragon" }
  validates :total_price_brutto, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, length: { maximum: 3 }
  validates :payment_method, presence: true, length: { maximum: 30 }
  validates :date_add, presence: true
  validates :receipt_number, presence: true, length: { maximum: 30 }
  validates :year, presence: true
  validates :month, presence: true
  validates :sub_id, presence: true
  validates :nip, length: { maximum: 30 }
  validates :external_receipt_number, length: { maximum: 30 }
  validates :external_id, length: { maximum: 30 }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) if status.present? }

  # Status color dla UI
  def status_color
    case status
    when "success"
      "gray"
    when "error"
      "red"
    end
  end

  # Status label dla UI
  def status_label
    case status
    when "success"
      "Sukces"
    when "error"
      "Błąd"
    end
  end

  def recalculate_totals
    total_brutto = receipt_items.sum { |item| item.price_brutto * item.quantity }
    update_columns(total_price_brutto: total_brutto)
  end

  def restore_products_from_order
    return false unless order.present?

    receipt_items.destroy_all

    snapshot_receipt_items

    recalculate_totals
    true
  end

  private

  def populate_from_order_snapshot
    return unless order

    date_add = order.order_date || order.created_at
    self.total_price_brutto ||= order.total_price
    self.currency ||= order.currency || "PLN"
    self.payment_method ||= order.payment_method
    self.date_add ||= date_add
    self.year ||= date_add.year
    self.month ||= date_add.month
    self.sub_id ||= next_sub_id
    self.receipt_number ||= "PA/#{self.sub_id}/#{self.month}/#{self.year}"
    self.nip ||= order.addresses.invoice.first.nip
  end

  def next_sub_id
    last_sub_id = account.receipts.where(year: year || (order.order_date || order.created_at).year).where(month: month || (order.order_date || order.created_at).month).maximum(:sub_id)
    last_sub_id ? last_sub_id + 1 : 1
  end

  def snapshot_receipt_items
    order.order_products.each do |op|
      receipt_items.create(name: op.name, sku: op.sku, ean: op.ean, price_brutto: op.gross_price, tax_rate: op.tax_rate, quantity: op.quantity)
    end
  end
end
