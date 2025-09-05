class PostsController < ApplicationController
  def index
    @posts = Post.where(published: true).order(published_date: :desc)

    @searched_posts = search_posts
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
    previous_published_post.nil? ? last_published_post : previous_published_post
  end

  def next_post
    next_published_post.nil? ? first_published_post : next_published_post
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

  def search_posts
    if params[:search].present? && params[:search].strip.present?
      post_ids = search_title | search_body | search_hashtags

      @searched_posts = post_ids.present? ? @posts.find(post_ids) : []
    end
  end

  def search_title
    @posts.where("title ilike ?", "%#{params[:search]}%").pluck(:id)
  end

  def search_body
    @posts.where("body ilike ?", "%#{params[:search]}%").pluck(:id)
  end

  def search_hashtags
    Post.joins(:hashtags).where(
      "hashtags.label ilike ?", "%#{params[:search]}%"
    ).pluck(:id)
  end
end
