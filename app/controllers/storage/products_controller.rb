class Storage::ProductsController < ApplicationController
  before_action :set_product, only: %i[ edit update destroy ]
  before_action :ensure_turbo_frame, only: %i[ edit new ]

  # GET /products or /products.json
  def index
    @per_page = params[:per_page].to_i
    @per_page = 20 if @per_page <= 0 || @per_page > 100 # domyślnie 20, max 100

    @products = Product.all.page(params[:page]).per(@per_page)
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
    @product.catalog ||= current_user.catalogs.first

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

  private

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
