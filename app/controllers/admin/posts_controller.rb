class Admin::PostsController < ApplicationController
  def new
    @post = Post.new
  end

  def create
    @post = Post.new(post_params)

    if @post.save
      redirect_to edit_admin_post_path(@post), alert: t("admin.flash.created")
    else
      redirect_to new_admin_post_path, alert: t("admin.flash.failed")
    end
  end

  def edit
    @post = find_post
  end

  private

  def find_post
    Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :body, :published, :published_date)
  end
end
