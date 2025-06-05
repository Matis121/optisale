# frozen_string_literal: true

class Ui::Order::Info::Component < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize(order:, order_statuses:)
    @order = order
    @order_statuses = order_statuses
  end
end
