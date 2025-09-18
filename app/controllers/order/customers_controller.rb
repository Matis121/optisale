class Order::CustomersController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :set_customer
  before_action :set_order, only: [ :edit, :update ]

  def edit
     unless request.headers["Turbo-Frame"].present?
      redirect_to order_path(@order), alert: "Brak dostępu"
     else
      render Ui::Order::Info::Customer::FormComponent.new(order: @order, customer: @customer)
     end
  end

  def update
    if @customer.update(customer_params)
      render turbo_stream: turbo_stream.replace(dom_id(@order, :customer), Ui::Order::Info::Customer::Component.new(order: @order))
    end
  end
  private

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def set_order
    @order = @customer.orders.find(params[:order_id])
  end

  def customer_params
    params.require(:customer).permit(:login, :email, :phone)
  end
end
