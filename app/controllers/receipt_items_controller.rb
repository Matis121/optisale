class ReceiptItemsController < ApplicationController
  before_action :set_receipt
  before_action :set_receipt_item, only: [ :destroy ]

  def destroy
    if @receipt_item.destroy
      recalculate_totals
      redirect_to @receipt, notice: "Produkt został usunięty z paragonu."
    else
      redirect_to @receipt, alert: "Nie udało się usunąć produktu z paragonu."
    end
  end

  private

  def set_receipt
    @receipt = current_account.receipts.find(params[:receipt_id])
  end

  def set_receipt_item
    @receipt_item = @receipt.receipt_items.find(params[:id])
  end

  def recalculate_totals
    total_brutto = @receipt.receipt_items.sum { |item| item.price_brutto * item.quantity }
    @receipt.update_columns(total_price_brutto: total_brutto)
  end
end
