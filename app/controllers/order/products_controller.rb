class Order::ProductsController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :set_order_product, only: [ :destroy, :edit, :update ]

  def new
    @order_product = OrderProduct.new
  end

  def edit
  end

  def update
    if @order_product.update(order_product_params)
      flash.now[:success] = "Produkt został zaktualizowany"
      update_product_table_frame_with_flash
    else
      flash[:error] = "Błąd podczas aktualizacji produktu"
      redirect_to @order_product.order
    end
  end

  def create
    @order_product = OrderProduct.new(product_params)
    @order_product.order_id = params.expect(:order_id)

    if @order_product.save
      respond_to do |format|
        format.json { render json: { success: true, order_product: @order_product }, status: :created }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, errors: @order_product.errors }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @order_product.destroy!
      flash.now[:success] = "Produkt został usunięty"
      update_product_table_frame_with_flash
    end
  end

  private

  def product_params
    params.require(:product).permit(:product_id, :quantity)
  end

  def order_product_params
    params.require(:order_product).permit(:quantity, :gross_price, :tax_rate, :ean, :sku, :name)
  end

  def update_product_table_frame_with_flash
    order = @order_product.order
    streams = []
    streams << turbo_stream.update("modal-frame", "")
    streams << turbo_stream.replace(dom_id(order, :product_table), Ui::Order::ProductTableComponent.new(order: order))
    streams << turbo_stream.replace(dom_id(order, :payment), Ui::Order::Info::Payment::Component.new(order: order))
    streams << turbo_stream.update("flash-messages", partial: "shared/flash_messages")
    render turbo_stream: streams
  end


  def set_order_product
    @order_product = OrderProduct.find(params.expect(:id))
  end
end
