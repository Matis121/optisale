class InvoicesController < ApplicationController
  before_action :set_invoice, only: [ :show, :destroy, :sync_status, :cancel_invoice, :delete_from_external ]

  def index
    @invoices = current_user.invoices.includes(:order, :invoicing_integration)

    # Filter by invoicing_integration_id if provided
    if params[:invoicing_integration_id].present?
      @invoices = @invoices.where(invoicing_integration_id: params[:invoicing_integration_id])
    end

    @invoices = @invoices.order(created_at: :desc)
                         .page(params[:page]).per(20)
  end

  def show
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

    invoice_service = InvoiceService.new(current_user)

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
    invoice_service = InvoiceService.new(current_user)

    begin
      if invoice_service.delete_invoice(@invoice)
        # Also delete from local database after successful deletion from external system
        @invoice.destroy

        respond_to do |format|
          format.html { redirect_to invoices_path, notice: "Faktura została usunięta." }
          format.turbo_stream {
            flash.now[:notice] = "Faktura została usunięta."
            # Check if we're on the invoices index page
            if request.referer&.include?("invoices")
              @invoices = current_user.invoices.includes(:order, :invoicing_integration)
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
              @invoices = current_user.invoices.includes(:order, :invoicing_integration)
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
            @invoices = current_user.invoices.includes(:order, :invoicing_integration)
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
  end

  private

  def set_invoice
    @invoice = current_user.invoices.find(params[:id])
  end
end
