# frozen_string_literal: true

class Order::ShippingAddressFormComponent < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize(address:)
    @address = address
  end
end
