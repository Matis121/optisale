# frozen_string_literal: true

class Order::ProductTableComponent < ViewComponent::Base
  def initialize (order:)
    @order = order
  end
end
