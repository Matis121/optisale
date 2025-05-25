# frozen_string_literal: true

class Order::OrderInfoFormComponent < ViewComponent::Base
    include Turbo::FramesHelper

  def initialize(order:)
    @order = order
  end

  attr_reader :order
end
