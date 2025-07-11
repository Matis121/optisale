class Storage::ProductsController < ApplicationController
  before_action :set_product, only: %i[ edit update destroy ]

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
        format.html { render :new, status: :unprocessable_entity }
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
        Rails.logger.debug "PRODUCT ERRORS: #{@product.errors.full_messages}"
        @product.product_stocks.each do |ps|
          Rails.logger.debug "PRODUCT_STOCK ERRORS: #{ps.errors.full_messages}"
        end
        @product.product_prices.each do |pp|
          Rails.logger.debug "PRODUCT_PRICE ERRORS: #{pp.errors.full_messages}"
        end
        format.html { render :edit, status: :unprocessable_entity }
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
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def product_params
      params.require(:product).permit(
        :name, :sku, :ean, :tax_rate, :catalog_id,
        product_stocks_attributes: [ :id, :warehouse_id, :quantity ],
        product_prices_attributes: [ :id, :price_group_id, :nett_price, :gross_price, :currency ]
      )
    end
end
