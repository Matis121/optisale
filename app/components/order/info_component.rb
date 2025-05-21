# frozen_string_literal: true

class Order::InfoComponent < ViewComponent::Base
  def initialize(order:, order_statuses:)
    @order = order
    @order_statuses = order_statuses
  end
end
