class OrdersController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :set_order, only: [ :show, :update, :destroy, :edit, :edit_extra_fields, :update_extra_fields ]
  before_action :set_order_statuses

  # GET /orders or /orders.json
  def index
    @order_counts = Order.group(:status_id).count
    @order_counts.default = 0

    if params[:status].present? && params[:status] != "all"
      @orders = Order.where(status_id: params[:status])
    else
      @orders = Order.all
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
      render Order::OrderInfoFormComponent.new(order: @order)
    end
  end

  def edit_extra_fields
    unless request.headers["Turbo-Frame"].present?
      redirect_to @order, alert: "Brak dostępu"
    else
      render Order::ExtraFieldsInfoFormComponent.new(order: @order)
    end
  end

  # PATCH/PUT /orders/1 or /orders/1.json
  def update
    if @order.update(order_params)
      render turbo_stream: turbo_stream.replace(dom_id(@order, :info), Order::OrderInfoComponent.new(order: @order))
    end
  end

  def update_extra_fields
    if @order.update(order_params)
      render turbo_stream: turbo_stream.replace(dom_id(@order, :extra_fields), Order::ExtraFieldsInfoComponent.new(order: @order))
    end
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
      params.require(:order).permit(:user_id, :status_id, :source, :shipping_cost, :shipping_method, :payment_method, :extra_field_1, :extra_field_2, :admin_comments)
    end

    def set_order_statuses
      @order_statuses = OrderStatus.all
    end
end
