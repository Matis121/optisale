class Order::ProductsController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :set_order_product, only: [ :destroy ]

  def new
    @order_product = OrderProduct.new
  end

  def create
    @order_product = OrderProduct.new(product_params)
    @order_product.order_id = params[:order_id]

    if @order_product.save
      respond_to do |format|
        format.html { redirect_to @order_product.order, notice: "Produkt został dodany" }
        format.json { render json: { success: true, order_product: @order_product }, status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_to @order_product.order, alert: "Błąd podczas dodawania produktu" }
        format.json { render json: { success: false, errors: @order_product.errors }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    order = @order_product.order
    if @order_product.destroy!
      render turbo_stream: [
        turbo_stream.replace(dom_id(order, :product_table), Ui::Order::ProductTableComponent.new(order: order)),
        turbo_stream.replace(dom_id(order, :payment), Ui::Order::Info::Payment::Component.new(order: order))
      ]
    end
  end

  private

  def product_params
    params.require(:product).permit(:product_id, :quantity)
  end


  def set_order_product
    @order_product = OrderProduct.find(params.expect(:id))
  end
end
