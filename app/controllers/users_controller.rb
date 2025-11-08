class UsersController < ApplicationController
  before_action :set_user, only: [ :edit, :update, :destroy ]
  before_action :set_users, only: %i[ index create update destroy ]
  before_action :ensure_turbo_frame, only: %i[ new edit ]

  def index
  end

  def new
    @user = current_account.users.build
  end

  def create
    @user = current_account.users.build(user_params)

    if @user.save
      flash.now[:success] = "Użytkownik został pomyślnie utworzony."
      update_users_frame_with_flash
    else
      render_users_form
    end
  end

  def edit
  end

  def update
    # Remove password fields if they are blank
    if user_params[:password].blank?
      params_to_update = user_params.except(:password, :password_confirmation)
    else
      params_to_update = user_params
    end

    if @user.update(params_to_update)
      flash.now[:success] = "Użytkownik został zaktualizowany."
      update_users_frame_with_flash
    else
      render_users_form
    end
  end

  def destroy
    if @user.destroy
      flash.now[:success] = "Użytkownik został usunięty."
      update_users_frame_with_flash
    else
      flash.now[:error] = "#{@user.errors.full_messages.join(", ")}"
      render_flash_messages
    end
  end

  private

  def ensure_turbo_frame
    unless turbo_frame_request?
      redirect_to manage_users_path
    end
  end

  def update_users_frame_with_flash
    streams = []
    streams << turbo_stream.update("modal-frame", "")
    streams << turbo_stream.update("users_frame", partial: "users/table")
    streams << turbo_stream.update("flash-messages", partial: "shared/flash_messages")
    render turbo_stream: streams
  end

  def render_users_form
    render turbo_stream: turbo_stream.replace("user-form", partial: "users/form")
  end

  def render_flash_messages
    render turbo_stream: turbo_stream.update("flash-messages", partial: "shared/flash_messages")
  end

  def set_user
    @user = current_account.users.find(params[:id])
  end

  def set_users
    @users = current_account.users.order(created_at: :asc)
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :role, :account_id, :account_name, :account_nip)
  end
end
