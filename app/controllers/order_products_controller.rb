class OrderProductsController < ApplicationController
  before_action :set_order_product, only: [ :destroy ]

  def new
    @order_product = OrderProduct.new
  end

  def create
    @order_product = OrderProduct.new(order_product_params)

    if @order_product.save
      redirect_to @order_product.order, notice: "Produkt został dodany"
    end
  end

  def destroy
    @order_product.destroy!

    respond_to do |format|
      format.json { head :no_content }
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
