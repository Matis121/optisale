class Order::CustomerPickupPointsController < ApplicationController
  include ActionView::RecordIdentifier

  def edit
    @order = Order.find(params[:order_id])
    @customer_pickup_point = @order.customer_pickup_point
    render Ui::Order::Address::PickupPoint::FormComponent.new(pickup_point: @customer_pickup_point)
  end

  def update
    @customer_pickup_point = CustomerPickupPoint.find(params[:id])
    @order = @customer_pickup_point.order

    if @customer_pickup_point.update(address_params)
      render turbo_stream: turbo_stream.replace(dom_id(@customer_pickup_point), Ui::Order::Address::PickupPoint::Component.new(order: @order))
    end
  end


  private

  def address_params
    params.require(:customer_pickup_point).permit(
      :name, :point_id, :address,
      :postcode, :city, :country,
    )
  end
end
