class InvoicesController < ApplicationController
  before_action :set_invoice, only: [ :show, :edit, :update, :destroy, :sync_status, :cancel_invoice, :delete_from_external, :restore_products, :restore_customer_data ]

  def index
    @invoices = current_account.invoices
  end

  def show
  end

  def edit
  end

  def update
    if @invoice.update(invoice_params)
      @invoice.recalculate_totals
      redirect_to @invoice, notice: "Faktura została zaktualizowana."
    else
      render :edit, status: :unprocessable_entity
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

    @invoice = current_account.invoices.new(order: order)

    if @invoice.save
      order.reload
      respond_to do |format|
        format.html { redirect_to order_path(order), notice: "Faktura została utworzona." }
      end
    else
      error_message = "Nie udało się utworzyć faktury: #{@invoice.errors.full_messages.join(', ')}"
      respond_to do |format|
        format.html { redirect_to order_path(order), alert: error_message }
      end
    end
  end

  def destroy
    @invoice.destroy
    redirect_to invoices_path, notice: "Faktura została usunięta z lokalnej bazy danych."
  end

  def sync_status
    if @invoice.sync_status!
      redirect_to @invoice, notice: "Status faktury został zsynchronizowany."
    else
      redirect_to @invoice, alert: "Nie udało się zsynchronizować statusu faktury."
    end
  end

  def cancel_invoice
    unless @invoice.invoicing_integration.ready?
      redirect_back_or_to(@invoice, alert: "Integracja nie jest aktywna. Nie można anulować faktury.")
      return
    end

    invoice_service = InvoiceService.new(current_account)

    if invoice_service.cancel_invoice(@invoice)
      redirect_to @invoice, notice: "Faktura została anulowana."
    else
      error_message = invoice_service.errors.any? ?
        "#{invoice_service.errors.join(', ')}" :
        "Nie udało się anulować faktury."
      redirect_to @invoice, alert: error_message
    end
  end

  def delete_from_external
    unless @invoice.invoicing_integration.ready?
      redirect_back_or_to(@invoice.order, alert: "Integracja nie jest aktywna. Nie można usunąć faktury z zewnętrznego systemu.")
      return
    end

    order = @invoice.order # Remember order before deleting invoice
    invoice_service = InvoiceService.new(current_account)

    begin
      if invoice_service.delete_invoice(@invoice)
        # Also delete from local database after successful deletion from external system
        @invoice.destroy
        order.reload


        respond_to do |format|
          format.html { redirect_to invoices_path, notice: "Faktura została usunięta." }
          format.turbo_stream {
            flash.now[:notice] = "Faktura została usunięta."
            # Check if we're on the invoices index page
            if request.referer&.include?("invoices")
              @invoices = current_account.invoices.includes(:order, :invoicing_integration)
                                     .order(created_at: :desc)
                                     .page(params[:page]).per(20)
              render turbo_stream: turbo_stream.replace("invoices_table",
                partial: "invoices/table")
            else
              # Original behavior for order page
              render turbo_stream: turbo_stream.replace("invoice_section_#{order.id}",
                partial: "orders/invoice_section", locals: { order: order })
            end
          }
        end
      else
        error_message = "Nie udało się usunąć faktury z zewnętrznego systemu."

        respond_to do |format|
          format.html { redirect_back_or_to(order, alert: error_message) }
          format.turbo_stream {
            flash.now[:alert] = error_message
            # Check if we're on the invoices index page
            if request.referer&.include?("invoices")
              @invoices = current_account.invoices.includes(:order, :invoicing_integration)
                                     .order(created_at: :desc)
                                     .page(params[:page]).per(20)
              render turbo_stream: turbo_stream.replace("invoices_table",
                partial: "invoices/table")
            else
              # Original behavior for order page
              render turbo_stream: turbo_stream.replace("invoice_section_#{order.id}",
                partial: "orders/invoice_section", locals: { order: order })
            end
          }
        end
      end
    rescue => e
      user_friendly_error = case e.message
      when /Unauthorized/
        "Błąd autoryzacji. Sprawdź dane logowania do #{@invoice.invoicing_integration.provider.humanize}."
      when /not found/i, /404/
        "Faktura nie została znaleziona w zewnętrznym systemie. Możliwe że została już usunięta."
      when /Connection/i, /timeout/i
        "Błąd połączenia z systemem fakturowania. Sprawdź połączenie internetowe."
      else
        "Nieoczekiwany błąd: #{e.message}"
      end

      error_message = "#{user_friendly_error}"

      respond_to do |format|
        format.html { redirect_back_or_to(order, alert: error_message) }
        format.turbo_stream {
          flash.now[:alert] = error_message
          # Check if we're on the invoices index page
          if request.referer&.include?("invoices")
            @invoices = current_account.invoices.includes(:order, :invoicing_integration)
                                   .order(created_at: :desc)
                                   .page(params[:page]).per(20)
            render turbo_stream: turbo_stream.replace("invoices_table",
              partial: "invoices/table")
          else
            order.reload
            render turbo_stream: turbo_stream.replace("invoice_section_#{order.id}",
              partial: "orders/invoice_section", locals: { order: order })
          end
        }
      end
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
end
