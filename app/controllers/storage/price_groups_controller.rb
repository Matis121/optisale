class Storage::PriceGroupsController < ApplicationController
  before_action :set_price_group, only: %i[ show edit update destroy ]
  before_action :ensure_turbo_frame, only: %i[ edit new ]
  before_action :set_price_groups, only: %i[ index create update destroy ]

  def index
  end

  def show
  end

  def new
    @price_group = PriceGroup.new
    set_catalogs
  end

  def edit
    set_catalogs
  end

  def create
    @price_group = PriceGroup.new(price_group_params)
    @price_group.user = current_user
    @price_group.catalogs = current_user.catalogs.where(id: price_group_params[:catalog_ids])

      if @price_group.save
        flash.now[:success] = "Grupa cenowa została utworzona."
        update_price_groups_frame_with_flash
      else
        set_catalogs
        render_price_groups_form
      end
  end

  def update
    if @price_group.update(price_group_params)
      flash.now[:success] = "Grupa cenowa została zaktualizowana."
      update_price_groups_frame_with_flash
    else
      set_catalogs
      render_price_groups_form
    end
  end

  def destroy
    @price_group.destroy!

    flash.now[:success] = "Grupa cenowa została usunięta."
    update_price_groups_frame_with_flash
  end

  private

  def set_catalogs
    @catalogs = current_user.catalogs
  end

  def update_price_groups_frame_with_flash
    streams = []
    streams << turbo_stream.update("modal-frame", "")
    streams << turbo_stream.update("price_groups_frame", partial: "storage/price_groups/table")
    streams << turbo_stream.update("flash-messages", partial: "shared/flash_messages")
    render turbo_stream: streams
  end

  def ensure_turbo_frame
    unless turbo_frame_request?
      redirect_to storage_price_groups_path
    end
  end

  def render_price_groups_form
    render turbo_stream: turbo_stream.replace("price-group-form", partial: "storage/price_groups/form")
  end

  def set_price_group
    @price_group = current_user.price_groups.find(params[:id])
  end

  def set_price_groups
    @price_groups = current_user.price_groups
  end

  def price_group_params
    params.require(:price_group).permit(:name, :default, catalog_ids: [])
  end
end
