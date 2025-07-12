class Storage::CatalogsController < ApplicationController
  before_action :set_catalog, only: %i[ show edit update destroy ]
  before_action :ensure_turbo_frame, only: %i[ edit new ]

  def index
    @catalogs = current_user.catalogs
  end

  def show
  end

  def new
    @catalog = Catalog.new
  end

  def edit
  end

  def create
    @catalog = Catalog.new(catalog_params)
    @catalog.user = current_user

    respond_to do |format|
      if @catalog.save
        format.html { redirect_to storage_catalogs_path, notice: "Katalog został utworzony." }
        format.json { render :show, status: :created, location: @catalog }
      else
      format.turbo_stream { render turbo_stream: turbo_stream.update("catalog-form", partial: "storage/catalogs/form") }
        format.json { render json: @catalog.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @catalog.update(catalog_params)
        format.html { redirect_to storage_catalogs_path, notice: "Katalog został zaktualizowany." }
        format.json { render :show, status: :ok, location: @catalog }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.update("catalog-form", partial: "storage/catalogs/form") }
        format.json { render json: @catalog.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @catalog.destroy!

    respond_to do |format|
      format.html { redirect_to storage_catalogs_path, status: :see_other, notice: "Katalog został usunięty." }
      format.json { head :no_content }
    end
  end

  private

    def ensure_turbo_frame
      unless turbo_frame_request?
        redirect_to storage_catalogs_path
      end
    end

    def set_catalog
      @catalog = current_user.catalogs.find(params[:id])
    end

    def catalog_params
      params.require(:catalog).permit(:name)
    end
end
