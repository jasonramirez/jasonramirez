class PostsController < ApplicationController
  def index
    @posts = Post.where(published: true).order(published_date: :desc)
  end

  def show
    @post = find_post
  end

  private

  def find_post
    Post.friendly.find(params[:id])
  end
end
