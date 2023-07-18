class Admins::PostsController < ApplicationController
  before_action :authenticate_admin!

  layout "admin"

  def index
    @posts = Post.all.order(published_date: :desc)
  end

  def new
    @post = Post.new
  end

  def edit
    @post = find_post
  end

  def create
    @post = Post.new(post_params)

    redirect_for_create
  end

  def update
    @post = find_post

    redirect_for_update
  end

  def destroy
    post = find_post

    redirect_for_destroy(post)
  end

  private

  def find_post
    Post.friendly.find(params[:id])
  end

  def preview_post
    params.has_key?(:preview)
  end

  def redirect_for_create
    if @post.save
      redirect_to edit_admins_post_path(@post), notice: t("admins.flash.created")
    else
      redirect_to new_admins_post_path, alert: t("admins.flash.failed")
    end
  end

  def redirect_for_update
    if @post.update(post_params)
      redirect_to edit_admins_post_path(@post), notice: t("admins.flash.updated")
    else
      redirect_to edit_admins_post_path(@post), alert: t("admins.flash.failed")
    end
  end

  def redirect_for_destroy(post)
    if post.destroy
      redirect_to admins_posts_path, notice: t("admins.flash.destroyed")
    else
      redirect_to admins_posts_path, alert: t("admins.flash.failed")
    end
  end

  def post_params
    params.require(:post).permit(
      :body,
      :long_title,
      :published,
      :published_date,
      :title,
      :video_src,
      hashtag_ids: [],
    )
  end
end
