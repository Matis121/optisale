class OrderStatusGroupsController < ApplicationController
  before_action :set_order_status_group, only: %i[ show edit update destroy ]
  before_action :ensure_turbo_frame, only: %i[ new edit ]

  # GET /order_status_groups
  def index
    @order_status_groups = current_user.order_status_groups.order(:position)
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
    @order_status_group.user = current_user

    respond_to do |format|
      if @order_status_group.save
        format.turbo_stream { render turbo_stream: turbo_stream.update("groups_frame", partial: "order_status_groups/table") }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.update("order-status-group-form", partial: "order_status_groups/form") }
      end
    end
  end

  # PATCH/PUT /order_status_groups/1
  def update
    respond_to do |format|
      if @order_status_group.update(order_status_group_params)
        format.turbo_stream { render turbo_stream: turbo_stream.update("groups_frame", partial: "order_status_groups/table") }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.update("order-status-group-form", partial: "order_status_groups/form") }
      end
    end
  end

  # DELETE /order_status_groups/1
  def destroy
    @order_status_group.destroy!
    redirect_to order_statuses_path, status: :see_other, notice: "Grupa statusów została usunięta."
  end

  private
  def ensure_turbo_frame
    unless turbo_frame_request?
      redirect_to order_statuses_path
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_order_status_group
    @order_status_group = current_user.order_status_groups.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def order_status_group_params
    params.expect(order_status_group: [ :name, :position ])
  end
end
