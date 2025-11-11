  # frozen_string_literal: true

  class Ui::Layout::Table::HeaderComponent < ViewComponent::Base
    attr_reader :title, :href, :text_button

    def initialize(title:, href: "", text_button:)
      @title = title
      @href = href
      @text_button = text_button
    end
  end
