class OrderProductsController < ApplicationController
  before_action :set_order_product, only: [ :destroy ]

  def new
    @order_product = OrderProduct.new
  end

  def create
    @order_product = OrderProduct.new(order_product_params)

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
    if @order_product.destroy!
      respond_to do |format|
        format.html { redirect_to @order_product.order, notice: "Produkt został usunięty" }
      end
    else
      respond_to do |format|
        format.html { redirect_to @order_product.order, alert: "Błąd podczas usuwania produktu" }
      end
    end
  end

  private

  def order_product_params
    params.require(:order_product).permit(:order_id, :product_id, :quantity)
  end


  def set_order_product
    @order_product = OrderProduct.find(params.expect(:id))
  end
end
