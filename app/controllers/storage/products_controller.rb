class Storage::ProductsController < ApplicationController
  before_action :set_product, only: %i[ edit update destroy ]
  before_action :ensure_turbo_frame, only: %i[ edit new ]
  before_action :set_current_catalog_in_session, only: %i[ index create update ]
  before_action :set_current_warehouse_in_session, only: %i[ index create update ]
  before_action :set_current_price_group_in_session, only: %i[ index create update ]


  # GET /products or /products.json
  def index
    @per_page = params[:per_page].to_i
    @per_page = 20 if @per_page <= 0 || @per_page > 100

    catalog = current_user.catalogs.find_by(id: session[:current_catalog_id])

    if catalog.nil?
      @products = Product.none.page(params[:page])
    else
      @q = catalog.products.ransack(params[:q])
      @products = @q.result
                    .includes(:product_stocks, :product_prices)
                    .order(:name)
                    .page(params[:page]).per(@per_page)
    end

    # Safe params for pagination links
    @search_params = params[:q]&.permit!
  end

  # GET /products/new
  def new
    @product = Product.new

    current_user.catalogs.first.warehouses.each do |warehouse|
      @product.product_stocks.build(warehouse: warehouse)
    end

    current_user.catalogs.first.price_groups.each do |price_group|
      @product.product_prices.build(price_group: price_group, currency: "PLN")
    end
  end

  # GET /products/1/edit
  def edit
    catalog = @product.catalog

    # Buduj brakujące product_stocks dla wszystkich magazynów w katalogu
    catalog.warehouses.each do |warehouse|
      unless @product.product_stocks.any? { |ps| ps.warehouse_id == warehouse.id }
        @product.product_stocks.build(warehouse: warehouse)
      end
    end

    # Buduj brakujące product_prices dla wszystkich grup cenowych w katalogu
    catalog.price_groups.each do |price_group|
      unless @product.product_prices.any? { |pp| pp.price_group_id == price_group.id }
        @product.product_prices.build(price_group: price_group, currency: "PLN")
      end
    end
  end

  # POST /products or /products.json
  def create
    @product = Product.new(product_params)
    @product.catalog = @current_catalog

    respond_to do |format|
      if @product.save
        format.html { redirect_to storage_products_path, notice: "Product was successfully created." }
        format.json { render :show, status: :created, location: @product }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.update("product-form", partial: "storage/products/form") }
      end
    end
  end

  # PATCH/PUT /products/1 or /products/1.json
  def update
    respond_to do |format|
      if @product.update(product_params)
        format.html { redirect_to storage_products_path, notice: "Product was successfully updated." }
        format.json { render :show, status: :ok, location: @product }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.update("product-form", partial: "storage/products/form") }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /products/1 or /products/1.json
  def destroy
    @product.destroy!

    respond_to do |format|
      format.html { redirect_to storage_products_path, status: :see_other, notice: "Produkt został usunięty." }
      format.json { head :no_content }
    end
  end


  def update_current_catalog_in_session
    catalog_id = params[:catalog_id]
    if current_user.catalogs.exists?(catalog_id)
      session[:current_catalog_id] = catalog_id
      # resetuj zależności przy zmianie katalogu
      session[:current_warehouse_id] = nil
      session[:current_price_group_id] = nil
    end
    redirect_to storage_products_path
  end

  def update_current_warehouse_in_session
    warehouse_id = params[:warehouse_id]
    if warehouse_id == "all"
      session[:current_warehouse_id] = nil
    else
      if current_user.warehouses.exists?(warehouse_id)
        session[:current_warehouse_id] = warehouse_id
      end
    end
    redirect_to storage_products_path
  end

  def update_current_price_group_in_session
    price_group_id = params[:price_group_id]
    if current_user.price_groups.exists?(price_group_id)
      session[:current_price_group_id] = price_group_id
    end
    redirect_to storage_products_path
  end

  private

  def set_current_catalog_in_session
    @current_catalog = current_user.catalogs.find_by(id: session[:current_catalog_id])
    unless @current_catalog
      @current_catalog = current_user.catalogs.first
      session[:current_catalog_id] = @current_catalog&.id
    end
  end

  def set_current_warehouse_in_session
    warehouse_id = session[:current_warehouse_id]

    if warehouse_id.present?
      @current_warehouse = @current_catalog.warehouses.find_by(id: warehouse_id)
      unless @current_warehouse
        session[:current_warehouse_id] = nil
      end
    else
      @current_warehouse = nil
    end
  end

  def set_current_price_group_in_session
    price_group_id = session[:current_price_group_id]
    @current_price_group = current_user.price_groups.find_by(id: price_group_id) if price_group_id.present?

    unless @current_price_group
      @current_price_group = current_user.price_groups.first
      session[:current_price_group_id] = @current_price_group&.id
    end
  end


  def ensure_turbo_frame
    unless turbo_frame_request?
      redirect_to storage_products_path
    end
  end

  def set_product
    @product = Product.find(params.expect(:id))
  end

  def product_params
    params.require(:product).permit(
      :name, :sku, :ean, :tax_rate, :catalog_id,
      product_stocks_attributes: [ :id, :warehouse_id, :quantity ],
      product_prices_attributes: [ :id, :price_group_id, :nett_price, :gross_price, :currency ]
    )
  end
end
