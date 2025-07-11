class Storage::WarehousesController < ApplicationController
  before_action :set_warehouse, only: %i[ show edit update destroy ]

  def index
    @warehouses = Warehouse.joins(:catalog).where(catalogs: { user: current_user }).includes(:catalog)
  end

  def show
  end

  def new
    @warehouse = Warehouse.new
    @catalogs = current_user.catalogs
  end

  def edit
    @catalogs = current_user.catalogs
  end

  def create
    @warehouse = Warehouse.new(warehouse_params)
    @warehouse.catalog = current_user.catalogs.find(warehouse_params[:catalog_id])

    respond_to do |format|
      if @warehouse.save
        format.html { redirect_to storage_warehouses_path, notice: "Magazyn został utworzony." }
        format.json { render :show, status: :created, location: @warehouse }
      else
        @catalogs = current_user.catalogs
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @warehouse.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @warehouse.update(warehouse_params)
        format.html { redirect_to storage_warehouses_path, notice: "Magazyn został zaktualizowany." }
        format.json { render :show, status: :ok, location: @warehouse }
      else
        @catalogs = current_user.catalogs
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @warehouse.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @warehouse.destroy!

    respond_to do |format|
      format.html { redirect_to storage_warehouses_path, status: :see_other, notice: "Magazyn został usunięty." }
      format.json { head :no_content }
    end
  end

  private
    def set_warehouse
      @warehouse = Warehouse.joins(:catalog).where(catalogs: { user: current_user }).find(params[:id])
    end

    def warehouse_params
      params.require(:warehouse).permit(:name, :default, :catalog_id)
    end
end
