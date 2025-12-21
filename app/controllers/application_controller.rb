class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :configure_permitted_parameters, if: :devise_controller?

  before_action :authenticate_user!
  before_action :set_current_user

  layout :set_layout

  helper_method :current_account

  private

  def set_current_user
    Current.user = current_user
  end


  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :account_name, :account_nip ])
  end

  def current_account
    @current_account ||= current_user&.account
  end

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
