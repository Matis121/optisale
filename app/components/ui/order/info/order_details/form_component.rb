# frozen_string_literal: true

class Ui::Order::Info::OrderDetails::FormComponent < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize(order:)
    @order = order
  end

  attr_reader :order
end
