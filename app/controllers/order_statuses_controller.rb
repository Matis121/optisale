class OrderStatusesController < ApplicationController
  before_action :set_order_status, only: %i[ show edit update destroy ]

  # GET /order_statuses or /order_statuses.json
  def index
    @order_statuses = current_user.order_statuses
  end

  # GET /order_statuses/1 or /order_statuses/1.json
  def show
  end

  # GET /order_statuses/new
  def new
    @order_status = OrderStatus.new
  end

  # GET /order_statuses/1/edit
  def edit
  end

  # POST /order_statuses or /order_statuses.json
  def create
    @order_status = OrderStatus.new(order_status_params)
    @order_status.user = current_user

    respond_to do |format|
      if @order_status.save
        format.html { redirect_to order_statuses_path, notice: "Order status was successfully created." }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.update("order-status-form", partial: "order_statuses/form") }
      end
    end
  end

  # PATCH/PUT /order_statuses/1 or /order_statuses/1.json
  def update
    respond_to do |format|
      if @order_status.update(order_status_params)
        format.html { redirect_to order_statuses_path, notice: "Order status was successfully updated." }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.update("order-status-form", partial: "order_statuses/form") }
      end
    end
  end

  # DELETE /order_statuses/1 or /order_statuses/1.json
  def destroy
    @order_status.destroy!

    respond_to do |format|
      format.html { redirect_to order_statuses_path, status: :see_other, notice: "Order status was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order_status
      @order_status = current_user.order_statuses.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def order_status_params
      params.expect(order_status: [ :full_name, :short_name, :user_id ])
    end
end
