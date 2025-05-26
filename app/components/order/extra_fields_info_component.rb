# frozen_string_literal: true

class Order::ExtraFieldsInfoComponent < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize(order:)
    @order = order
  end
end
