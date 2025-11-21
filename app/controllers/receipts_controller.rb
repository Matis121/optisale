class ReceiptsController < ApplicationController
  before_action :set_receipt, only: [ :show, :edit, :update, :destroy, :restore_products ]
  before_action :set_receipts, only: [ :index, :destroy ]

  def index
  end

  def show
  end

  def edit
  end

  def update
    if @receipt.update(receipt_params)
      @receipt.recalculate_totals
      flash.now[:notice] = "Paragon został zaktualizowany."
      redirect_to @receipt, notice: "Paragon został zaktualizowany."
    else
      flash.now[:alert] = "Nie udało się zaktualizować paragonu: #{@receipt.errors.full_messages.join(', ')}"
      render_flash_messages
    end
  end

  def create
    unless params[:order_id]
      redirect_to orders_path, alert: "Brak order_id."
      return
    end

    order = current_account.orders.find_by(id: params[:order_id])
    unless order
      redirect_to orders_path, alert: "Zamówienie nie zostało znalezione."
      return
    end

    @receipt = current_account.receipts.new(order: order)

    if @receipt.save
      order.association(:receipt).reload
      flash.now[:notice] = "Paragon został utworzony."
      render_order_documents(order)
    else
      error_message = "Nie udało się utworzyć paragonu: #{@receipt.errors.full_messages.join(', ')}"
      flash.now[:alert] = error_message
      render_flash_messages
    end
  end

  def destroy
    order = @receipt.order
    if @receipt.destroy
      order.association(:receipt).reload if order
      flash.now[:notice] = "Paragon został usunięty z lokalnej bazy danych."

      if request.referer.match?(%r{/receipts/\d+})
        redirect_to receipts_path, notice: "Paragon został usunięty."
      elsif request.referer.include?("receipts")
        render_receipts_table
      else
        render_order_documents(order) if order
      end
    else
      flash.now[:alert] = "Nie udało się usunąć paragonu z lokalnej bazy danych."
      render_flash_messages
    end
  end

  # Przywraca produkty z zamówienia do paragonu
  def restore_products
    if @receipt.restore_products_from_order
      redirect_to @receipt, notice: "Produkty zostały przywrócone z zamówienia."
    else
      redirect_to @receipt, alert: "Nie udało się przywrócić produktów z zamówienia."
    end
  end

  private

  def receipt_params
    params.require(:receipt).permit(
      :receipt_number, :series_id, :year, :month, :sub_id, :date_add, :payment_method, :nip, :currency, :total_price_brutto, :external_receipt_number, :external_id
    )
  end

  def set_receipt
    @receipt = current_account.receipts.find(params[:id])
  end

  def set_receipts
    @receipts = current_account.receipts
  end

  def render_flash_messages
    render turbo_stream: turbo_stream.update("flash-messages", partial: "shared/flash_messages")
  end

  def render_receipts_table
    streams = []
    streams << turbo_stream.replace("receipts_table", partial: "receipts/table")
    streams << turbo_stream.update("flash-messages", partial: "shared/flash_messages")
    render turbo_stream: streams
  end

  def render_order_documents(order)
    streams = []
    streams << turbo_stream.replace("order_documents_#{order.id}", partial: "orders/invoice_section", locals: { order: order })
    streams << turbo_stream.update("flash-messages", partial: "shared/flash_messages")
    render turbo_stream: streams
  end
end
