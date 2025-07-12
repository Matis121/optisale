class Storage::PriceGroupsController < ApplicationController
  before_action :set_price_group, only: %i[ show edit update destroy ]
  before_action :ensure_turbo_frame, only: %i[ edit new ]

  def index
    @price_groups = PriceGroup.joins(:catalog).where(catalogs: { user: current_user }).includes(:catalog)
  end

  def show
  end

  def new
    @price_group = PriceGroup.new
    @catalogs = current_user.catalogs
  end

  def edit
    @catalogs = current_user.catalogs
  end

  def create
    @price_group = PriceGroup.new(price_group_params)
    @price_group.catalog = current_user.catalogs.find(price_group_params[:catalog_id])

    respond_to do |format|
      if @price_group.save
        format.html { redirect_to storage_price_groups_path, notice: "Grupa cenowa została utworzona." }
        format.json { render :show, status: :created, location: @price_group }
      else
        @catalogs = current_user.catalogs
        format.turbo_stream { render turbo_stream: turbo_stream.update("price-group-form", partial: "storage/price_groups/form") }
        format.json { render json: @price_group.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @price_group.update(price_group_params)
        format.html { redirect_to storage_price_groups_path, notice: "Grupa cenowa została zaktualizowana." }
        format.json { render :show, status: :ok, location: @price_group }
      else
        @catalogs = current_user.catalogs
        format.turbo_stream { render turbo_stream: turbo_stream.update("price-group-form", partial: "storage/price_groups/form") }
        format.json { render json: @price_group.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @price_group.destroy!

    respond_to do |format|
      format.html { redirect_to storage_price_groups_path, status: :see_other, notice: "Grupa cenowa została usunięta." }
      format.json { head :no_content }
    end
  end

  private

  def ensure_turbo_frame
    unless turbo_frame_request?
      redirect_to storage_price_groups_path
    end
  end

  def set_price_group
    @price_group = PriceGroup.joins(:catalog).where(catalogs: { user: current_user }).find(params[:id])
  end

  def price_group_params
    params.require(:price_group).permit(:name, :catalog_id)
  end
end
