# frozen_string_literal: true

class Ui::Layout::Table::DefaultComponent < ViewComponent::Base
  renders_one :header, Ui::Layout::Table::HeaderComponent
  renders_one :table_header
  renders_one :table_body
end
