class Admins::PostsController < ApplicationController
  before_action :authenticate_admin!

  layout "admin"

  def index
    @posts = Post.all.order(published_date: :desc)
  end

  def new
    post = Post.new(default_post)

    if post.save
      redirect_after_success(edit_admins_post_path(post), "created")
    else
      redirect_after_failure(admins_posts_path)
    end
  end

  def show
    @post = find_post
  end

  def edit
    @post = find_post
  end

  def create
    @post = Post.new(post_params)

    if @post.save
      render_turbo_steam("save")
    else
      render_turbo_steam("failure")
    end
  end

  def update
    @post = find_post
    @old_slug = @post.slug

    if @post.update(post_params)
      @slug_changed = @old_slug != @post.slug
      render_turbo_steam("update")
    else
      render_turbo_steam("failure")
    end
  end

  def destroy
    post = find_post

    if post.destroy
      redirect_to admins_posts_path, notice: t("admins.flash.destroyed")
    else
      redirect_to edit_admins_post_path(post), alert: t("admins.flash.failed")
    end
  end

  private

  def find_post
    Post.friendly.find(params[:id])
  end

  def preview_post
    params.has_key?(:preview)
  end

  def render_turbo_steam(stream_name)
    respond_to do |format|
      format.turbo_stream do
        render stream_name
      end
    end
  end

  def redirect_after_success(path, message)
    redirect_to path, notice: t("admins.flash.#{message}")
  end

  def redirect_after_failure(path)
    redirect_to path, alert: t("admins.flash.failed")
  end

  def default_post
    {
      title: "Draft",
      published: false,
      published_date: Time.now,
    }
  end

  def post_params
    params.require(:post).permit(
      :post_markdown,
      :summary,
      :tldr_transcript,
      :published,
      :published_date,
      :title,
      :video_src,
      :audio_src,
      hashtag_ids: [],
    )
  end
end
