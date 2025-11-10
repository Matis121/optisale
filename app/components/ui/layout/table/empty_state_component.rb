class Ui::Layout::Table::EmptyStateComponent < ViewComponent::Base
  attr_reader :icon, :title, :paragraph, :href, :text_button, :href_turbo

  def initialize(icon:, title:, paragraph:, href:, text_button:, href_turbo: true)
    @icon = icon
    @title = title
    @paragraph = paragraph
    @href = href
    @text_button = text_button
    @href_turbo = href_turbo
  end
end
