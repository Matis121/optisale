# frozen_string_literal: true

class Ui::Order::Info::ExtraFields::Component < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize(order:)
    @order = order
  end
end
