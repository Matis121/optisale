class InvoiceService
  attr_reader :user, :errors

  def initialize(user)
    @user = user
    @errors = []
  end

  # Creates invoice for order using active integration
  def create_invoice_for_order(order, invoicing_integration_id: nil)
    # Check if invoice can be created for this order
    unless can_generate_invoice_for_order?(order)
      @errors << "Nie można utworzyć faktury dla tego zamówienia"
      return false
    end

    invoicing_integration = find_invoicing_integration(invoicing_integration_id)
    return false unless invoicing_integration

    begin
      invoice = invoicing_integration.adapter.create_invoice(order)
      invoice.present?
    rescue => e
      @errors << "Błąd tworzenia faktury: #{e.message}"
      false
    end
  end

  # Synchronizes all user invoices
  def sync_all_invoices
    user.invoices.joins(:invoicing_integration)
        .where(invoicing_integrations: { active: true })
        .find_each do |invoice|
      invoice.sync_status!
    end
  end

  # Cancels invoice
  def cancel_invoice(invoice)
    begin
      if invoice.invoicing_integration.adapter.cancel_invoice(invoice)
        invoice.update!(status: "cancelled")
        true
      else
        @errors << "Nie udało się anulować faktury w zewnętrznym systemie"
        false
      end
    rescue => e
      @errors << "Błąd anulowania faktury: #{e.message}"
      false
    end
  end

  # Deletes invoice from external system and locally
  def delete_invoice(invoice)
    begin
      if invoice.invoicing_integration.adapter.delete_invoice(invoice)
        invoice.destroy
        true
      else
        @errors << "Nie udało się usunąć faktury z zewnętrznego systemu"
        false
      end
    rescue => e
      @errors << "Błąd usuwania faktury: #{e.message}"
      false
    end
  end

  # Checks if user has active integration
  def has_active_invoicing_integration?
    user.invoicing_integrations.active_integrations.exists?
  end

  # Returns user's active integration
  def active_invoicing_integration
    user.invoicing_integrations.active_integrations.first
  end

  # Checks if order can have invoice generated
  def can_generate_invoice_for_order?(order)
    unless has_active_invoicing_integration?
      @errors << "Brak aktywnej integracji fakturowania"
      return false
    end

    if order.user != user
      @errors << "Zamówienie należy do innego użytkownika"
      return false
    end

    if order.invoice.present?
      @errors << "Zamówienie już ma fakturę"
      return false
    end

    if order.order_products.empty?
      @errors << "Zamówienie nie ma produktów"
      return false
    end

    true
  end

  # Returns invoices for order
  def invoice_for_order(order)
    order.invoice.includes(:invoicing_integration)
  end

  private

  def find_invoicing_integration(invoicing_integration_id = nil)
    if invoicing_integration_id
      invoicing_integration = user.invoicing_integrations.active_integrations.find_by(id: invoicing_integration_id)
      @errors << "Nie znaleziono aktywnej integracji o ID #{invoicing_integration_id}" unless invoicing_integration
    else
      invoicing_integration = active_invoicing_integration
      @errors << "Brak aktywnej integracji fakturowania" unless invoicing_integration
    end

    invoicing_integration
  end
end
