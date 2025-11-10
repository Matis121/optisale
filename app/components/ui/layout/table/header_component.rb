  # frozen_string_literal: true

  class Ui::Layout::Table::HeaderComponent < ViewComponent::Base
    attr_reader :title, :href

    def initialize(title:, href: "")
      @title = title
      @href = href
    end
  end
