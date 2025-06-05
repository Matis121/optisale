# frozen_string_literal: true

class Ui::Order::Address::PickupPoint::FormComponent < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize (pickup_point:)
    @pickup_point = pickup_point
  end

  attr_reader :pickup_point
end
