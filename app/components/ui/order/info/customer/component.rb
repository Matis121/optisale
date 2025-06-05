# frozen_string_literal: true

class Ui::Order::Info::Customer::Component < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize(order:)
    @order = order
    @customer = @order.customer
  end
end
