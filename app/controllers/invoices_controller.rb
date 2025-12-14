class InvoicesController < ApplicationController
  before_action :set_invoice, only: [ :show, :edit, :update, :destroy, :restore_products, :restore_customer_data, :download_pdf ]
  before_action :set_invoices, only: [ :index, :destroy ]
  before_action :set_order, only: [ :create ]

  def index
  end

  def show
  end

  def edit
  end

  def update
    if @invoice.update(invoice_params)
      @invoice.recalculate_totals
      flash.now[:notice] = "Faktura została zaktualizowana."
      redirect_to @invoice, notice: "Faktura została zaktualizowana."
    else
      flash.now[:alert] = "Nie udało się zaktualizować faktury: #{@invoice.errors.full_messages.join(', ')}"
      render_flash_messages
    end
  end

  def create
    @invoice = current_account.invoices.new(order: @order)

    if @invoice.save
      @order.reload
      flash.now[:notice] = "Faktura została utworzona."
      render_order_documents(@order)
    else
      error_message = "Nie udało się utworzyć faktury: #{@invoice.errors.full_messages.join(', ')}"
      flash.now[:alert] = error_message
      render_flash_messages
    end
  end

  def destroy
    order = @invoice.order

    begin
      @invoice.delete_from_external!
    rescue => e
      flash.now[:alert] = e.message
      render_flash_messages
      return
    end

    if @invoice.destroy
      order.association(:invoice).reload
      flash.now[:notice] = "Faktura została usunięta."
      if request.referer.match?(%r{/invoices/\d+})
        redirect_to invoices_path, notice: "Faktura została usunięta."
      elsif request.referer.include?("invoices")
        render_invoices_table
      else
        render_order_documents(order) if order
      end
    else
      flash.now[:alert] = "Nie udało się usunąć faktury z lokalnej bazy danych."
      render_flash_messages
    end
  end

  # Przywraca produkty z zamówienia do faktury
  def restore_products
    if @invoice.restore_products_from_order
      redirect_to @invoice, notice: "Produkty zostały przywrócone z zamówienia."
    else
      redirect_to @invoice, alert: "Nie udało się przywrócić produktów z zamówienia."
    end
  end

  def restore_customer_data
    if @invoice.restore_customer_data_from_order
      redirect_to @invoice, notice: "Dane klienta zostały przywrócone z zamówienia."
    else
      redirect_to @invoice, alert: "Nie udało się przywrócić danych klienta z zamówienia."
    end
  end

  def download_pdf
    pdf_data = @invoice.download_pdf

    if pdf_data
      send_data pdf_data, filename: "#{@invoice.external_invoice_number}.pdf", type: "application/pdf"
    else
      redirect_to @invoice, alert: "Nie udało się pobrać PDF faktury."
    end
  end


  private

  def invoice_params
    params.require(:invoice).permit(
      :invoice_fullname, :invoice_company, :invoice_nip,
      :invoice_street, :invoice_city, :invoice_postcode, :invoice_country,
      :additional_info, :payment_method, :seller, :issuer, :external_invoice_number
    )
  end


  def set_invoice
    @invoice = current_account.invoices.find(params[:id])
  end

  def set_invoices
    @invoices = current_account.invoices
  end

  def set_order
    @order = current_account.orders.find_by(id: params[:order_id])
  end

  def render_flash_messages
    render turbo_stream: turbo_stream.update("flash-messages", partial: "shared/flash_messages")
  end

  def render_invoices_table
      render turbo_stream: turbo_stream.replace("invoices_table", partial: "invoices/table")
  end

  def render_order_documents(order)
    streams = []
    streams << turbo_stream.replace("order_documents_#{order.id}", partial: "orders/invoice_section", locals: { order: order })
    streams << turbo_stream.update("flash-messages", partial: "shared/flash_messages")
    render turbo_stream: streams
  end
end
