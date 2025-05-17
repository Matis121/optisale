# frozen_string_literal: true

class Order::CustomerPickupPointFormComponent < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize (pickup_point:)
    @pickup_point = pickup_point
  end

  attr_reader :pickup_point
end
