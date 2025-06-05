# frozen_string_literal: true

class Ui::Order::Address::PickupPoint::Component < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize (order:)
    @order = order
    @pickup_point = @order.customer_pickup_point
  end

  attr_reader :pickup_point
end
