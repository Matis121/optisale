# frozen_string_literal: true

class Ui::Layout::Header::DefaultComponent < ViewComponent::Base
  attr_reader :title

  def initialize(title:)
    @title = title
  end
end
