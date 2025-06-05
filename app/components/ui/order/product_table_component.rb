# frozen_string_literal: true

class Ui::Order::ProductTableComponent < ViewComponent::Base
  def initialize (order:)
    @order = order
  end
end
