class PostsController < ApplicationController
  def index
    @posts = Post.where(published: true).order(published_date: :desc)
  end

  def show
    @post = find_post

    @next_post = next_post
    @previous_post = previous_post
  end

  private

  def find_post
    Post.friendly.find(params[:id])
  end

  def previous_post
    if previous_published_post.nil?
      last_published_post
    else
      previous_published_post
    end
  end

  def next_post
    if next_published_post.nil?
      first_published_post
    else
      next_published_post
    end
  end

  def next_published_post
    Post.where("published_date < ?", @post.published_date)
      .where(published: true)
      .order(published_date: :desc)
      .first
  end

  def previous_published_post
    Post.where("published_date > ?", @post.published_date)
      .where(published: true)
      .order(published_date: :asc)
      .first
  end

  def first_published_post
    Post.where(published: true).order(published_date: :desc).first
  end

  def last_published_post
    Post.where(published: true).order(published_date: :asc).first
  end
end
