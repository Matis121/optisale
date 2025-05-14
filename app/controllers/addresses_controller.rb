class AddressesController < ApplicationController
  include ActionView::RecordIdentifier
  def edit
    @order = Order.find(params[:order_id])
    @address = @order.addresses.find(params[:id])
    render Order::ShippingAddressFormComponent.new(address: @address)
  end

  def update
    @address = Address.find(params[:id])
    @order = @address.order

    if @address.update(address_params)
      render turbo_stream: turbo_stream.replace(dom_id(@address), Order::ShippingAddressComponent.new(order: @order, address_type: 0))
    end
  end

  private

  def address_params
    params.require(:address).permit(
      :fullname, :company_name, :street,
      :postcode, :city, :country, :country_code
    )
  end
end
