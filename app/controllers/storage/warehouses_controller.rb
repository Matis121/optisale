class Storage::WarehousesController < ApplicationController
  before_action :set_warehouse, only: %i[ show edit update destroy ]
  before_action :set_warehouses, only: %i[ index create update destroy ]
  before_action :set_catalogs, only: %i[ new edit create update destroy ]
  before_action :ensure_turbo_frame, only: %i[ edit new ]

  def index
  end

  def show
  end

  def new
    @warehouse = Warehouse.new
  end

  def edit
  end

  def create
    @warehouse = Warehouse.new(warehouse_params)
    @warehouse.account = current_account
    @warehouse.catalogs = current_account.catalogs.where(id: warehouse_params[:catalog_ids])

      if @warehouse.save
        flash.now[:success] = "Magazyn został utworzony."
        update_warehouses_frame_with_flash
      else
        set_catalogs
        render_warehouses_form
      end
  end

  def update
      if @warehouse.update(warehouse_params)
        flash.now[:success] = "Magazyn został zaktualizowany."
        update_warehouses_frame_with_flash
      else
        set_catalogs
        render_warehouses_form
      end
  end

  def destroy
    if @warehouse.destroy
      flash.now[:success] = "Magazyn został usunięty."
      update_warehouses_frame_with_flash
    else
      flash.now[:error] = "#{@warehouse.errors.full_messages.join(", ")}"
      update_warehouses_frame_with_flash
    end
  end

  private

    def ensure_turbo_frame
      unless turbo_frame_request?
        redirect_to storage_warehouses_path
      end
    end

    def render_warehouses_form
      render turbo_stream: turbo_stream.replace("warehouse-form", partial: "storage/warehouses/form")
    end

    def set_warehouses
      @warehouses = current_account.warehouses.order(created_at: :asc)
    end

    def set_warehouse
      @warehouse = current_account.warehouses.find(params[:id])
    end

    def set_catalogs
      @catalogs = current_account.catalogs
    end

    def update_warehouses_frame_with_flash
      streams = []
      streams << turbo_stream.update("modal-frame", "")
      streams << turbo_stream.update("warehouses_frame", partial: "storage/warehouses/table")
      streams << turbo_stream.update("flash-messages", partial: "shared/flash_messages")
      render turbo_stream: streams
    end

    def warehouse_params
      params.require(:warehouse).permit(:name, :default, catalog_ids: [])
    end
end
