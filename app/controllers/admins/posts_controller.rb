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

    if @post.update(post_params)
      render_turbo_steam("update")
    else
      render_turbo_steam("failure")
    end
  end

  def destroy
    post = find_post

    if post.destroy
      redirect_after_success(admins_posts_path, "destroyed")
    else
      redirect_after_failure(edit_admins_posts_path(@post))
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
      :body,
      :summary,
      :published,
      :published_date,
      :title,
      :video_src,
      hashtag_ids: [],
    )
  end
end
