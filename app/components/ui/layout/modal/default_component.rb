# frozen_string_literal: true

class Ui::Layout::Modal::DefaultComponent < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize(title:)
    @title = title
  end
end
