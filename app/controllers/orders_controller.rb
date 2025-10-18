class OrdersController < ApplicationController
  include ActionView::RecordIdentifier

  DEFAULT_PER_PAGE = 20
  MAX_PER_PAGE = 100

  before_action :set_order, only: [ :show, :update, :destroy, :edit, :edit_extra_fields, :update_extra_fields, :edit_payment, :update_payment, :generate_invoice ]
  before_action :set_order_statuses

  # GET /orders or /orders.json
  def index
    @order_counts = current_user.orders.group(:status_id).count
    @order_counts.default = 0

    @per_page = params[:per_page].to_i
    @per_page = DEFAULT_PER_PAGE if @per_page <= 0 || @per_page > MAX_PER_PAGE

    orders_scope = current_user.orders

    # Handle status group filtering
    if params[:status_group].present?
      status_group = current_user.order_status_groups.find_by(id: params[:status_group])
      if status_group
        status_ids = status_group.order_statuses.pluck(:id)
        orders_scope = orders_scope.where(status_id: status_ids)
      end
    # Handle status filtering
    elsif params[:status].present?
      unless params[:status] == "all"
        status_id = params[:status].to_i
        orders_scope = orders_scope.where(status_id: status_id)
      end
    else
      # If no status is provided, default to showing only orders with the first status
      default_status_id = @order_statuses.first&.id
      orders_scope = orders_scope.where(status_id: default_status_id) if default_status_id
    end

    # Then apply filters from params[:q]
    @q = orders_scope.ransack(params[:q])
    @orders = @q.result
                .includes(:order_status, :addresses, :order_products)
                .order(created_at: :desc)
                .page(params[:page]).per(@per_page)

    # Safe params for pagination links
    @search_params = params[:q]&.permit!
  end

  # GET /orders/1 or /orders/1.json
  def show
    @order_counts = current_user.orders.group(:status_id).count
    @order_counts.default = 0
  end

  # GET /orders/new
  def new
    @order = Order.new
  end

  # GET /orders/1/edit

  # POST /orders or /orders.json
  def create
    @order = Order.new
    @order.user = current_user
    @order.status_id = OrderStatus.first&.id

    if @order.save
      redirect_to @order, notice: "Zamówienie zostało utworzone."
    else
      render :orders, status: :unprocessable_entity
    end
  end

  def edit
    unless request.headers["Turbo-Frame"].present?
      redirect_to @order, alert: "Brak dostępu"
    else
      render Ui::Order::Info::OrderDetails::FormComponent.new(order: @order)
    end
  end

  def edit_extra_fields
    unless request.headers["Turbo-Frame"].present?
      redirect_to @order, alert: "Brak dostępu"
    else
      render Ui::Order::Info::ExtraFields::FormComponent.new(order: @order)
    end
  end

  def edit_payment
    unless request.headers["Turbo-Frame"].present?
      redirect_to @order, alert: "Brak dostępu"
    else
      render Ui::Order::Info::Payment::FormComponent.new(order: @order)
    end
  end

  # GET /orders/:id/search_products
  def search_products
    @order = Order.find(params[:id])
    query = params[:query]&.strip
    catalog_id = params[:catalog_id]

    # Get all catalogs for the current user
    catalogs = current_user.catalogs

    # Filter by catalog if specified
    if catalog_id.present?
      catalogs = catalogs.where(id: catalog_id)
    end

    # Get products from the catalogs
    products = Product.joins(:catalog).where(catalog: catalogs)
                      .includes(:product_prices, :product_stocks)

    # Apply search filter
    if query.present?
      products = products.where("products.name ILIKE ? OR products.sku ILIKE ? OR products.ean ILIKE ?",
                               "%#{query}%", "%#{query}%", "%#{query}%")
    end

    # Pagination
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 20
    per_page = [ per_page, 100 ].min # Max 100 items per page

    products = products.page(page).per(per_page)

    result = products.map do |product|
      default_price_group = current_user.price_groups.find_by(default: true)

      product_price = product.product_prices.find { |pp| pp.price_group_id == default_price_group&.id } || product.product_prices.first

      {
        id: product.id,
        name: product.name,
        sku: product.sku,
        ean: product.ean,
        tax_rate: product.tax_rate,
        gross_price: product_price&.gross_price || 0,
        stock: product.product_stocks.sum(:quantity)
      }
    end

    render json: {
      products: result,
      pagination: {
        current_page: page,
        per_page: per_page,
        total_count: products.total_count,
        total_pages: products.total_pages,
        has_next: products.next_page.present?,
        has_prev: products.prev_page.present?
      }
    }
  end

  # PATCH/PUT /orders/1 or /orders/1.json
  def update
    if @order.update(order_params)
      render turbo_stream: turbo_stream.replace(dom_id(@order, :info), Ui::Order::Info::OrderDetails::Component.new(order: @order))
    end
  end

  def update_extra_fields
    if @order.update(order_params)
      render turbo_stream: turbo_stream.replace(dom_id(@order, :extra_fields), Ui::Order::Info::ExtraFields::Component.new(order: @order))
    end
  end

  def update_payment
    case params[:set_amount_paid]
    when "full"
      @order.amount_paid = @order.total_price
    when "zero"
      @order.amount_paid = 0.0
    else
      @order.assign_attributes(order_params)
    end

   if @order.save
    render turbo_stream: turbo_stream.replace(
      dom_id(@order, :payment),
      Ui::Order::Info::Payment::Component.new(order: @order)
    )
   end
  end

  def bulk_update
    order_ids = JSON.parse(params[:order_ids]).reject(&:blank?)

    if order_ids.empty?
      flash[:notice] = "Nie wybrano zamówienia."
      redirect_to request.referer || orders_path
      return
    end

    @orders = Order.where(id: order_ids)

    if params[:delete] == "1"
      @orders.destroy_all
      flash[:success] = "Zmiany zostały wprowadzone."
      redirect_to request.referer || orders_path
      return
    end

    if params[:order_status_id].present?
      @orders.update_all(status_id: params[:order_status_id])
      flash[:success] = "Zmiany zostały wprowadzone."
      redirect_to request.referer || orders_path
      return
    end

    head :ok
  end


  # DELETE /orders/1 or /orders/1.json
  def destroy
    @order.destroy!

    respond_to do |format|
      format.html { redirect_to orders_path, status: :see_other, notice: "Order was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def generate_invoice
    invoice_service = InvoiceService.new(current_user)

    # Check if invoice can be generated
    unless invoice_service.can_generate_invoice_for_order?(@order)
      error_message = invoice_service.errors.any? ?
        "Nie można wygenerować faktury: #{invoice_service.errors.join(', ')}" :
        "Nie można wygenerować faktury dla tego zamówienia."
      redirect_to @order, alert: error_message
      return
    end

    # Attempt to create invoice
    begin
      if invoice_service.create_invoice_for_order(@order)
        respond_to do |format|
          format.html { redirect_to @order, notice: "Faktura została pomyślnie wygenerowana!" }
          format.turbo_stream {
            flash.now[:notice] = "Faktura została pomyślnie wygenerowana!"
            render turbo_stream: turbo_stream.replace("invoice_section_#{@order.id}",
              partial: "orders/invoice_section", locals: { order: @order })
          }
        end
      else
        # Format errors for user
        formatted_errors = invoice_service.errors.map do |error|
          case error
          when /undefined method.*name.*Customer/
            "Brak danych klienta (imię/nazwa). Uzupełnij dane klienta w zamówieniu."
          when /undefined method.*email.*Customer/
            "Brak adresu email klienta. Uzupełnij email klienta w zamówieniu."
          when /Unauthorized/
            "Błąd autoryzacji. Sprawdź dane logowania do #{invoice_service.active_integration.provider.humanize}."
          when /Connection/i
            "Błąd połączenia z systemem fakturowania. Sprawdź połączenie internetowe."
          when /SSL/i, /certificate/i
            "Błąd certyfikatu SSL. Problem z bezpiecznym połączeniem."
          else
            error # Show original error if no special formatting available
          end
        end

        error_message = "Błąd podczas generowania faktury: #{formatted_errors.join(', ')}"

        respond_to do |format|
          format.html { redirect_to @order, alert: error_message }
          format.turbo_stream {
            flash.now[:alert] = error_message
            render turbo_stream: turbo_stream.replace("invoice_section_#{@order.id}",
              partial: "orders/invoice_section", locals: { order: @order })
          }
        end
      end
    rescue => e
      # Handle unexpected exceptions
      user_friendly_error = case e.message
      when /undefined method.*name.*Customer/
        "Brak wymaganych danych klienta. Uzupełnij imię/nazwę klienta w zamówieniu."
      when /undefined method.*email.*Customer/
        "Brak adresu email klienta. Uzupełnij email klienta w zamówieniu."
      when /Connection refused/, /timeout/i
        "Nie można połączyć się z systemem fakturowania. Sprawdź połączenie internetowe."
      when /SSL/i, /certificate/i
        "Problem z certyfikatem bezpieczeństwa. Skontaktuj się z administratorem."
      else
        "Nieoczekiwany błąd: #{e.message}"
      end

      error_message = "#{user_friendly_error}"

      respond_to do |format|
        format.html { redirect_to @order, alert: error_message }
        format.turbo_stream {
          flash.now[:alert] = error_message
          render turbo_stream: turbo_stream.replace("invoice_section_#{@order.id}",
            partial: "orders/invoice_section", locals: { order: @order })
        }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order
      @order = Order.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def order_params
      params.require(:order).permit(:user_id, :status_id, :source, :shipping_cost, :shipping_method, :payment_method, :extra_field_1, :extra_field_2, :admin_comments, :amount_paid)
    end

    def set_order_statuses
      @order_statuses = current_user.order_statuses.order(:position)
      @order_status_groups = current_user.order_status_groups.joins(:order_statuses).includes(:order_statuses).order(:position).distinct
      @ungrouped_statuses = current_user.order_statuses.where(order_status_group_id: nil).order(:position)
    end
end
