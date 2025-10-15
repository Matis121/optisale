class OrderStatusesController < ApplicationController
  before_action :set_order_status, only: %i[ show edit update destroy ]
  before_action :ensure_turbo_frame, only: %i[ new edit ]

  # GET /order_statuses
  def index
    @order_statuses = current_user.order_statuses.order(:position)
    @order_status_groups = current_user.order_status_groups.order(:position)
  end

  # GET /order_statuses/1
  def show
  end

  # GET /order_statuses/new
  def new
    @order_status = OrderStatus.new
    @groups = current_user.order_status_groups.order(:position)
  end

  # GET /order_statuses/1/edit
  def edit
    @groups = current_user.order_status_groups.order(:position)
  end

  # POST /order_statuses
  def create
    @order_status = OrderStatus.new(order_status_params)
    @order_status.user = current_user
    @groups = current_user.order_status_groups.order(:position)

    respond_to do |format|
      if @order_status.save
        format.html { redirect_to order_statuses_path, notice: "Status zamówienia został utworzony." }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.update("order-status-form", partial: "order_statuses/form") }
      end
    end
  end

  # PATCH/PUT /order_statuses/1
  def update
    @groups = current_user.order_status_groups.order(:position)
    respond_to do |format|
      if @order_status.update(order_status_params)
        format.html { redirect_to order_statuses_path, notice: "Status zamówienia został zaktualizowany." }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.update("order-status-form", partial: "order_statuses/form") }
      end
    end
  end

  # DELETE /order_statuses/1
  def destroy
    if @order_status.default?
      redirect_to order_statuses_path, status: :see_other, alert: "Nie można usunąć domyślnego statusu."
    else
      @order_status.destroy!
      redirect_to order_statuses_path, status: :see_other, notice: "Status zamówienia został usunięty."
    end
  end

  private
  def ensure_turbo_frame
    unless turbo_frame_request?
      redirect_to order_statuses_path
    end
  end

    # Use callbacks to share common setup or constraints between actions.
    def set_order_status
      @order_status = current_user.order_statuses.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def order_status_params
      params.expect(order_status: [ :full_name, :short_name, :user_id, :position, :color, :order_status_group_id ])
    end
end
