class Admins::PostsController < ApplicationController
  before_action :authenticate_admin!

  layout "admin"

  def index
    @posts = Post.all
  end

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(post_params)

    if @post.save
      flash[:success] = t("admins.flash.created")
      render "edit"
    else
      flash[:alert] = t("admins.flash.failed")
      render "new"
    end
  end

  def edit
    @post = find_post
  end

  def update
    @post = find_post

    if @post.update_attributes(post_params)
      flash[:success] = t("admins.flash.updated")
      render "edit"
    else
      flash[:alert] = t("admins.flash.failed")
      render "edit"
    end
  end

  def destroy
    post = find_post

    if post.destroy
      flash[:success] = t("admins.flash.destroyed")
      redirect_to admins_posts_path
    else
      flash[:alert] = t("admins.flash.failed")
      render "index"
    end
  end

  private

  def find_post
    Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :body, :published, :published_date)
  end
end
