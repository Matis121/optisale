# frozen_string_literal: true

class Ui::Order::Address::Shipping::Component < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize (order:, address_type:)
    @order = order
    @address_type = address_type
  end

  def address
    @order.addresses.find_by(kind: @address_type)
  end
end
