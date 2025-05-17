# frozen_string_literal: true

class Order::CustomerPickupPointComponent < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize (order:)
    @order = order
    @pickup_point = @order.customer_pickup_point
  end

  attr_reader :pickup_point
end
