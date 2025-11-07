class OrderStatusGroupsController < ApplicationController
  before_action :set_order_status_group, only: %i[ show edit update destroy ]
  before_action :ensure_turbo_frame, only: %i[ new edit ]

  # GET /order_status_groups
  def index
    @order_status_groups = current_account.order_status_groups.order(:position)
  end

  # GET /order_status_groups/1
  def show
  end

  # GET /order_status_groups/new
  def new
    @order_status_group = OrderStatusGroup.new
  end

  # GET /order_status_groups/1/edit
  def edit
  end

  # POST /order_status_groups
  def create
    @order_status_group = OrderStatusGroup.new(order_status_group_params)
    @order_status_group.account = current_account

      if @order_status_group.save
        flash.now[:success] = "Grupa statusów została utworzona."
        update_groups_frame_with_flash
      else
        render_order_status_groups_form
      end
  end

  # PATCH/PUT /order_status_groups/1
  def update
      if @order_status_group.update(order_status_group_params)
        flash.now[:success] = "Grupa statusów została zaktualizowana."
        update_groups_frame_with_flash
      else
        render_order_status_groups_form
      end
  end

  # DELETE /order_status_groups/1
  def destroy
    @order_status_group.destroy!
    flash.now[:success] = "Grupa statusów została usunięta."
    update_groups_frame_with_flash
  end

  private
  def ensure_turbo_frame
    unless turbo_frame_request?
      redirect_to order_statuses_path
    end
  end

  def render_order_status_groups_form
    render turbo_stream: turbo_stream.replace("order-status-group-form", partial: "order_status_groups/form")
  end


  def render_flash_messages
    render turbo_stream: turbo_stream.update("flash-messages", partial: "shared/flash_messages")
  end


  def update_groups_frame_with_flash
    streams = []

    streams << turbo_stream.update("modal-frame", "")
    streams << turbo_stream.update("groups_frame", partial: "order_status_groups/table")
    streams << turbo_stream.update("flash-messages", partial: "shared/flash_messages")

    render turbo_stream: streams
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_order_status_group
    @order_status_group = current_account.order_status_groups.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def order_status_group_params
    params.expect(order_status_group: [ :name, :position ])
  end
end
