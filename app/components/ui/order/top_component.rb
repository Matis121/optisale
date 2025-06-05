# frozen_string_literal: true

class Ui::Order::TopComponent < ViewComponent::Base
  def initialize(order_id:)
    @order_id = order_id
  end
end
