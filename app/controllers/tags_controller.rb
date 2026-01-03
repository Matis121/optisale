class TagsController < ApplicationController
  before_action :set_tag, only: %i[ show edit update destroy ]
  before_action :ensure_turbo_frame, only: %i[ new edit ]
  before_action :set_tags, only: %i[ index create update destroy ]

  def index
    @tags = current_account.tags.order(:position)
  end

  def show
  end

  def new
    @tag = Tag.new
  end

  def edit
  end

  def create
    @tag = Tag.new(tag_params)
    @tag.account = current_account

    if @tag.save
      flash.now[:success] = "Tag został utworzony."
      update_tags_frame_with_flash
    else
      render_tags_form
    end
  end

  def update
    if @tag.update(tag_params)
      flash.now[:success] = "Tag został zaktualizowany."
      update_tags_frame_with_flash
    else
      render_tags_form
    end
  end

  def destroy
    if @tag.destroy
      flash.now[:success] = "Tag został usunięty."
      update_tags_frame_with_flash
    else
      flash.now[:error] = "#{@tag.errors.full_messages.join(", ")}"
      update_tags_frame_with_flash
    end
  end

  private

  def cleanup_orphaned_taggings
    return unless saved_change_to_scopes?

    unless scopes.include?("orders")
      taggings.where(taggable_type: "Order").destroy_all
    end

    unless scopes.include?("products")
      taggings.where(taggable_type: "Product").destroy_all
    end
  end

  def set_tags
    @tags = current_account.tags.order(:position)
  end

  def set_tag
    @tag = current_account.tags.find(params[:id])
  end

  def tag_params
    params.require(:tag).permit(:name, :color, :position, scopes: [])
  end

  def ensure_turbo_frame
    unless turbo_frame_request?
      redirect_to tags_path
    end
  end

  def update_tags_frame_with_flash
    streams = []
    streams << turbo_stream.update("modal-frame", "")
    streams << turbo_stream.update("tags_frame", partial: "tags/table")
    streams << turbo_stream.update("flash-messages", partial: "shared/flash_messages")
    render turbo_stream: streams
  end

  def render_tags_form
    render turbo_stream: turbo_stream.replace("tag-form", partial: "tags/form")
  end

  def render_flash_messages
    render turbo_stream: turbo_stream.update("flash-messages", partial: "shared/flash_messages")
  end
end
