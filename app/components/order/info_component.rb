# frozen_string_literal: true

class Order::InfoComponent < ViewComponent::Base
  def initialize(order:)
    @order = order
  end
end
