class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!

  layout :set_layout

  private

  def set_layout
    return false if turbo_stream_request? || api_request? || turbo_frame_request?

    if current_user.present?
      "application"
    else
      "authentication"
    end
  end

  def turbo_stream_request?
    request.format.turbo_stream? || request.headers["Accept"]&.include?("turbo-stream")
  end

  def turbo_frame_request?
    request.headers["Turbo-Frame"].present?
  end

  def api_request?
    request.format.json? || request.format.api?
  end
end
