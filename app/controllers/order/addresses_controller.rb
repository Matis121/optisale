class Order::AddressesController < ApplicationController
  include ActionView::RecordIdentifier
  def edit
    unless request.headers["Turbo-Frame"].present?
      redirect_to root_path, alert: "Brak dostępu"
    else
      @order = Order.find(params[:order_id])
      @address = @order.addresses.find(params[:id])
      render Ui::Order::Address::Shipping::FormComponent.new(address: @address)
    end
  end

  def update
    @address = Address.find(params[:id])
    @order = @address.order

    if @address.update(address_params)
      render turbo_stream: turbo_stream.replace(dom_id(@address), Ui::Order::Address::Shipping::Component.new(order: @order, address_type: @address.kind))
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
