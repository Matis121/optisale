class OrdersController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :set_order, only: [ :show, :update, :destroy, :edit, :edit_extra_fields, :update_extra_fields, :edit_payment, :update_payment ]
  before_action :set_order_statuses

  # GET /orders or /orders.json
  def index
    @order_counts = Order.group(:status_id).count
    @order_counts.default = 0

    @per_page = params[:per_page].to_i
    @per_page = 20 if @per_page <= 0 || @per_page > 100 # domyślnie 20, max 100

    if params[:status].present? && params[:status] != "all"
      @orders = Order.where(status_id: params[:status]).page(params[:page]).per(@per_page).order(created_at: :desc)
    else
      @orders = Order.all.page(params[:page]).per(@per_page).order(created_at: :desc)
    end
  end

  # GET /orders/1 or /orders/1.json
  def show
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
    order_ids = Array(params[:order_ids]).compact_blank

    if order_ids.empty?
      redirect_to orders_path, alert: "Nie wybrano żadnych zamówień."
      return
    end

    @orders = Order.where(id: order_ids)

    if params[:delete] == "1"
      Order.where(id: order_ids).destroy_all
    elsif params[:order_status_id].present?
      Order.where(id: order_ids).update_all(status_id: params[:order_status_id])
    end

    redirect_to orders_path, notice: "Zamówienia zostały zaktualizowane."
  end

  # DELETE /orders/1 or /orders/1.json
  def destroy
    @order.destroy!

    respond_to do |format|
      format.html { redirect_to orders_path, status: :see_other, notice: "Order was successfully destroyed." }
      format.json { head :no_content }
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
      @order_statuses = OrderStatus.all
    end
end
