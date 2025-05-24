# frozen_string_literal: true

class Order::CustomerInfoComponent < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize(order:)
    @order = order
    @customer = @order.customer
  end
end
