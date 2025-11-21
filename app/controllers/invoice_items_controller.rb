class InvoiceItemsController < ApplicationController
  before_action :set_invoice
  before_action :set_invoice_item, only: [ :destroy ]

  def destroy
    if @invoice_item.destroy
      recalculate_totals
      redirect_to @invoice, notice: "Produkt został usunięty z faktury."
    else
      redirect_to @invoice, alert: "Nie udało się usunąć produktu z faktury."
    end
  end

  private

  def set_invoice
    @invoice = current_account.invoices.find(params[:invoice_id])
  end

  def set_invoice_item
    @invoice_item = @invoice.invoice_items.find(params[:id])
  end

  def recalculate_totals
    total_brutto = @invoice.invoice_items.sum { |item| item.price_brutto * item.quantity }
    total_netto = @invoice.invoice_items.sum { |item| item.price_netto * item.quantity }
    @invoice.update_columns(total_price_brutto: total_brutto, total_price_netto: total_netto)
  end
end
