class Invoice < ApplicationRecord
  belongs_to :account
  belongs_to :order
  has_many :invoice_items, dependent: :destroy

  enum :status, {
    success: "success",
    error: "error"
  }

  before_validation :populate_from_order_snapshot, if: -> { order.present? && new_record? }
  after_create :snapshot_invoice_items

  validates :total_price_brutto, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_price_netto, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, length: { maximum: 3 }
  validates :payment_method, presence: true, length: { maximum: 100 }
  validates :date_add, presence: true
  validates :date_sell, presence: true
  validates :invoice_number, presence: true, length: { maximum: 30 }
  validates :invoice_fullname, presence: true, length: { maximum: 100 }
  validates :invoice_street, presence: true, length: { maximum: 100 }
  validates :invoice_city, presence: true, length: { maximum: 100 }
  validates :invoice_postcode, presence: true, length: { maximum: 100 }
  validates :invoice_country, presence: true, length: { maximum: 50 }
  validates :invoice_company, presence: true, length: { maximum: 100 }
  validates :invoice_nip, presence: true, length: { maximum: 100 }
  validates :external_invoice_number, length: { maximum: 30 }
  validates :issuer, length: { maximum: 100 }
  validates :seller, length: { maximum: 250 }
  validates :additional_info, length: { maximum: 500 }
  validates :order_id, uniqueness: { scope: :account_id, message: "może mieć tylko jedną fakturę" }

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

  def restore_products_from_order
    return false unless order.present?

    invoice_items.destroy_all

    snapshot_invoice_items

    recalculate_totals
    true
  end

  def restore_customer_data_from_order
    return false unless order.present?

    self.invoice_fullname = nil
    self.invoice_company = nil
    self.invoice_street = nil
    self.invoice_city = nil
    self.invoice_postcode = nil
    self.invoice_country = nil

    populate_from_order_snapshot

    save
  end

  def recalculate_totals
    total_brutto = invoice_items.sum { |item| item.price_brutto * item.quantity }
    total_netto = invoice_items.sum { |item| item.price_netto * item.quantity }
    update_columns(total_price_brutto: total_brutto, total_price_netto: total_netto)
  end

  private

  def populate_from_order_snapshot
    return unless order

    invoice_address = order.addresses.invoice.first

    # Dane adresowe z zamówienia (snapshot) - tylko jeśli nie są już ustawione
    self.invoice_fullname ||= invoice_address&.fullname
    self.invoice_company ||= invoice_address&.company_name
    self.invoice_street ||= invoice_address&.street
    self.invoice_city ||= invoice_address&.city
    self.invoice_postcode ||= invoice_address&.postcode
    self.invoice_country ||= invoice_address&.country || "PL"
    self.invoice_nip ||= invoice_address&.nip

    # Identyfikatory i daty
    sell_date = order.order_date || order.created_at
    self.month ||= sell_date.month
    self.year ||= sell_date.year
    self.sub_id ||= next_sub_id
    self.invoice_number ||= "FV/#{self.sub_id}/#{self.month}/#{self.year}"

    # Ceny (snapshot z zamówienia)
    self.total_price_brutto ||= order.total_price
    self.total_price_netto ||= calculate_total_netto

    # Waluta i metoda płatności
    self.currency ||= order.currency || "PLN"
    self.payment_method ||= order.payment_method

    # Daty
    self.date_add ||= Time.current
    self.date_sell ||= sell_date
  end

  def calculate_total_netto
    return 0 unless order

    # Oblicz cenę netto dla każdego produktu i zsumuj
    netto_sum = order.order_products.sum do |op|
      gross_price = op.gross_price || 0
      tax_rate = op.tax_rate || 0

      if tax_rate.to_f.zero?
        gross_price * op.quantity
      else
        net_price = gross_price / (1 + tax_rate.to_f / 100.0)
        (net_price * op.quantity).round(2)
      end
    end

    # Dodaj koszt wysyłki
    shipping_netto = if order.shipping_cost && order.shipping_cost > 0
      avg_tax_rate = order.order_products.any? ?
        order.order_products.sum(&:tax_rate).to_f / order.order_products.count : 23.0
      if avg_tax_rate > 0
        order.shipping_cost / (1 + avg_tax_rate / 100.0)
      else
        order.shipping_cost
      end
    else
      0
    end

    (netto_sum + shipping_netto).round(2)
  end

  def next_sub_id
    # Znajdź ostatni sub_id dla tego konta (i opcjonalnie miesiąca/roku)
    last_sub_id = account.invoices
      .where(year: year || (order.order_date || order.created_at).year)
      .where(month: month || (order.order_date || order.created_at).month)
      .maximum(:sub_id)

    # Jeśli nie ma faktur, zacznij od 1, w przeciwnym razie dodaj 1
    last_sub_id ? last_sub_id + 1 : 1
  end

  def snapshot_invoice_items
    order.order_products.each do |op|
      price_netto = op.gross_price / (1 + op.tax_rate.to_f / 100.0).round(2)
      invoice_items.create(name: op.name, sku: op.sku, ean: op.ean, price_brutto: op.gross_price, price_netto: price_netto, tax_rate: op.tax_rate, quantity: op.quantity)
    end
  end
end
