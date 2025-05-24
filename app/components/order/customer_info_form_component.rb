# frozen_string_literal: true

class Order::CustomerInfoFormComponent < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize(order:, customer:)
    @order = order
    @customer = customer
  end

  attr_reader :customer, :order
end
