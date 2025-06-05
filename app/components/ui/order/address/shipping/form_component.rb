# frozen_string_literal: true

class Ui::Order::Address::Shipping::FormComponent < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize(address:)
    @address = address
  end
end
