class Storage::CatalogsController < ApplicationController
  before_action :set_catalog, only: %i[ show edit update destroy ]
  before_action :set_catalogs, only: %i[ index create update destroy ]
  before_action :ensure_turbo_frame, only: %i[ edit new ]

  def index
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

    if @catalog.save
      flash.now[:success] = "Katalog został utworzony."
      update_catalogs_frame_with_flash
    else
      render_catalogs_form
    end
  end

  def update
      if @catalog.update(catalog_params)
        flash.now[:success] = "Katalog został zaktualizowany."
        update_catalogs_frame_with_flash
      else
        render_catalogs_form
      end
  end

  def destroy
    @catalog.destroy!
    flash.now[:success] = "Katalog został usunięty."
    update_catalogs_frame_with_flash
  end

  private

  def set_catalogs
    @catalogs = current_user.catalogs
  end

  def update_catalogs_frame_with_flash
    streams = []
    streams << turbo_stream.update("modal-frame", "")
    streams << turbo_stream.update("catalogs_frame", partial: "storage/catalogs/table")
    streams << turbo_stream.update("flash-messages", partial: "shared/flash_messages")
    render turbo_stream: streams
  end

  def render_catalogs_form
    render turbo_stream: turbo_stream.replace("catalog-form", partial: "storage/catalogs/form")
  end

  def ensure_turbo_frame
    unless turbo_frame_request?
      redirect_to storage_catalogs_path
    end
  end

  def set_catalog
    @catalog = current_user.catalogs.find(params[:id])
  end

  def catalog_params
    params.require(:catalog).permit(:name, :default)
  end
end
