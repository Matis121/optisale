# frozen_string_literal: true

class Ui::Layout::Toast::DefaultComponent < ViewComponent::Base
  def initialize(message:, type: :info)
    @message = message
    @type = type.to_sym
  end

  private

  def type_classes
    case @type
    when :success
      "bg-green-50 border-green-200"
    when :error, :danger
      "bg-red-50 border-red-200"
    when :warning
      "bg-yellow-50 border-yellow-200"
    when :info, :notice
      "bg-blue-50 border-blue-200"
    else
      "bg-gray-50 border-gray-200"
    end
  end

  def icon_bg_class
    case @type
    when :success
      "bg-green-500"
    when :error, :danger
      "bg-red-500"
    when :warning
      "bg-yellow-500"
    when :info, :notice
      "bg-blue-500"
    else
      "bg-gray-500"
    end
  end

  def icon_class
    case @type
    when :success
      "fas fa-check"
    when :error, :danger
      "fas fa-times"
    when :warning
      "fas fa-exclamation"
    when :info, :notice
      "fas fa-info"
    else
      "fas fa-info"
    end
  end
end
