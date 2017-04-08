class Admins::PostsController < ApplicationController
  before_action :authenticate_admin!

  layout "admin"

  def index
    @posts = Post.all.order(published_date: :desc)
  end

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(post_params)

    if @post.save
      redirect_to edit_admins_post_path(@post), notice: t("admins.flash.created")
    else
      redirect_to new_admins_post_path, alert: t("admins.flash.failed")
    end
  end

  def edit
    @post = find_post
  end

  def update
    @post = find_post

    if @post.update_attributes(post_params)
      redirect_to edit_admins_post_path, notice: t("admins.flash.updated")
    else
      redirect_to edit_admins_post_path, alert: t("admins.flash.failed")
    end
  end

  def destroy
    post = find_post

    if post.destroy
      redirect_to admins_posts_path, notice: t("admins.flash.destroyed")
    else
      redirect_to admins_posts_path, alert: t("admins.flash.failed")
    end
  end

  private

  def find_post
    Post.friendly.find(params[:id])
  end

  def post_params
    params.require(:post).permit(
      :body,
      :long_title,
      :published,
      :published_date,
      :title,
    )
  end
end
