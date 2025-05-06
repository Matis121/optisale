# frozen_string_literal: true

class Order::TopComponent < ViewComponent::Base
  def initialize(order_id:)
    @order_id = order_id
  end
end
