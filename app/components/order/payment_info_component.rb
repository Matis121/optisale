# frozen_string_literal: true

class Order::PaymentInfoComponent < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize(order:)
    @order = order
  end
end
