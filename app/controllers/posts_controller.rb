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

  def feed
    @posts = Post.where(published: true)
                 .order(published_date: :desc)
    
    render json: {
      version: "https://jsonfeed.org/version/1.1",
      title: "Jason Ramirez - Blog Posts",
      home_page_url: root_url,
      feed_url: url_for(controller: 'posts', action: 'feed', format: :json, only_path: false),
      description: "Latest blog posts and insights from Jason Ramirez on product design, leadership, and innovation",
      copyright: "© #{Date.current.year} Jason Ramirez. All rights reserved.",
      license: "All content copyright Jason Ramirez. Please link back to the original post when referencing.",
      author: {
        name: "Jason Ramirez",
        url: root_url,
        bio: "Product Design Leader"
      },
      items: @posts.map do |post|
        {
          id: post_url(post),
          url: post_url(post),
          external_url: post_url(post), # Canonical URL for attribution
          title: post.title,
          content_text: post.post_text,
          content_html: post.parsed_body,
          summary: post.summary,
          date_published: post.published_date&.iso8601,
          date_modified: post.updated_at.iso8601,
          tags: post.hashtags.map(&:label),
          authors: [
            {
              name: "Jason Ramirez",
              url: root_url
            }
          ],
          attribution: "Originally published at #{post_url(post)}"
        }
      end
    }
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

      @searched_posts = post_ids.present? ? @posts.where(id: post_ids) : []
    else
      @searched_posts = []
    end
  end

  def search_title
    @posts.where("title ilike ?", "%#{params[:search]}%").pluck(:id)
  end

  def search_body
    # Search both post_text (plain text) and post_markdown for better coverage
    text_ids = @posts.where("post_text ilike ?", "%#{params[:search]}%").pluck(:id)
    markdown_ids = @posts.where("post_markdown ilike ?", "%#{params[:search]}%").pluck(:id)
    (text_ids + markdown_ids).uniq
  end

  def search_hashtags
    Post.joins(:hashtags).where(
      "hashtags.label ilike ?", "%#{params[:search]}%"
    ).pluck(:id)
  end
end
