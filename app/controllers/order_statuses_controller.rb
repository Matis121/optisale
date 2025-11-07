class OrderStatusesController < ApplicationController
  before_action :set_order_status, only: %i[ show edit update destroy ]
  before_action :set_order_statuses, only: %i[ index update create destroy ]
  before_action :set_groups, only: %i[ new edit create update ]
  before_action :ensure_turbo_frame, only: %i[ new edit ]

  # GET /order_statuses
  def index
    @order_status_groups = current_account.order_status_groups.order(:position)
  end

  # GET /order_statuses/1
  def show
  end

  # GET /order_statuses/new
  def new
    @order_status = OrderStatus.new
  end

  # GET /order_statuses/1/edit
  def edit
  end

  # POST /order_statuses
  def create
    @order_status = OrderStatus.new(order_status_params)
    @order_status.account = current_account

    if @order_status.save
      flash.now[:success] = "Status zamówienia został utworzony."
     update_statuses_frame_with_flash
    else
      render_statuses_form
    end
  end

  # PATCH/PUT /order_statuses/1
  def update
    if @order_status.update(order_status_params)
      flash.now[:success] = "Status zamówienia został zaktualizowany."
      update_statuses_frame_with_flash
    else
      render_statuses_form
    end
  end

  # DELETE /order_statuses/1
  def destroy
    if @order_status.default?
      flash.now[:error] = "Nie można usunąć domyślnego statusu."
      render_flash_messages
    elsif @order_status.orders.any?
      flash.now[:error] = "Nie można usunąć statusu, jeśli znajdują się w nim zamówienia."
      render_flash_messages
    else
      if @order_status.destroy
        flash.now[:success] = "Status zamówienia został usunięty."
        update_statuses_frame_with_flash
      else
        flash.now[:error] = @order_status.errors.full_messages.join(", ")
        render_flash_messages
      end
    end
  end

  private

  def set_order_statuses
    @order_statuses = current_account.order_statuses.order(:position)
  end

  def set_groups
    @groups = current_account.order_status_groups.order(:position)
  end

  def ensure_turbo_frame
    unless turbo_frame_request?
      redirect_to order_statuses_path
    end
  end

  def render_flash_messages
    render turbo_stream: turbo_stream.update("flash-messages", partial: "shared/flash_messages")
  end

  def render_statuses_form
    render turbo_stream: turbo_stream.replace("order-status-form", partial: "order_statuses/form")
  end

  def update_statuses_frame_with_flash
    streams = []

    streams << turbo_stream.update("modal-frame", "")
    streams << turbo_stream.update("statuses_frame", partial: "order_statuses/table")
    streams << turbo_stream.update("flash-messages", partial: "shared/flash_messages")

    render turbo_stream: streams
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_order_status
    @order_status = current_account.order_statuses.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def order_status_params
    params.expect(order_status: [ :full_name, :short_name, :user_id, :position, :color, :order_status_group_id ])
  end
end
