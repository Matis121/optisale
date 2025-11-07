class Invoice < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :order
  belongs_to :invoicing_integration

  enum :status, {
    draft: "draft",
    sent: "sent",
    paid: "paid",
    partial: "partial",
    cancelled: "cancelled",
    error: "error"
  }

  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :external_id, presence: true, uniqueness: { scope: :invoicing_integration_id }
  validates :invoice_number, presence: true
  validates :order_id, uniqueness: { scope: :account_id, message: "może mieć tylko jedną fakturę" }

  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }
  scope :by_status, ->(status) { where(status: status) if status.present? }

  # Deserializuje external_data z JSON
  def external_data
    return {} if super.blank?

    begin
      JSON.parse(super).with_indifferent_access
    rescue JSON::ParserError
      {}
    end
  end

  # Serializes external_data to JSON
  def external_data=(value)
    if value.is_a?(Hash)
      super(value.to_json)
    elsif value.is_a?(String)
      super(value)
    end
  end

  # Delegates to adapter
  def view_url
    invoicing_integration.adapter.view_url(self)
  rescue
    external_url
  end

  def download_pdf_url
    invoicing_integration.adapter.download_pdf_url(self)
  rescue
    nil
  end

  # Synchronizes status with external system
  def sync_status!
    return false unless invoicing_integration.ready?

    new_status = invoicing_integration.adapter.get_invoice_status(self)

    if new_status && new_status != status
      update!(status: new_status)
      true
    else
      false
    end
  rescue
    update!(status: "error") unless error?
    false
  end

  # Cancels invoice in external system
  def cancel!
    return false unless invoicing_integration.ready?
    return false if cancelled?

    if invoicing_integration.adapter.cancel_invoice(self)
      update!(status: "cancelled")
      true
    else
      false
    end
  rescue
    false
  end

  # Checks if invoice can be cancelled
  def cancellable?
    !cancelled? && !error? && invoicing_integration&.ready?
  end

  # Formats amount for display
  def formatted_amount
    "#{amount} PLN"
  end

  # Sprawdza czy faktura jest przeterminowana
  def overdue?
    due_date && due_date < Date.current && !paid?
  end

  # Returns number of days until payment due date
  def days_until_due
    return nil unless due_date

    (due_date - Date.current).to_i
  end

  # Status color dla UI
  def status_color
    case status
    when "draft"
      "gray"
    when "sent"
      "blue"
    when "paid"
      "green"
    when "partial"
      "yellow"
    when "cancelled"
      "red"
    when "error"
      "red"
    else
      "gray"
    end
  end

  # Status label dla UI
  def status_label
    case status
    when "draft"
      "Szkic"
    when "sent"
      "Wysłana"
    when "paid"
      "Opłacona"
    when "partial"
      "Częściowo opłacona"
    when "cancelled"
      "Anulowana"
    when "error"
      "Błąd"
    else
      status.humanize
    end
  end
end
