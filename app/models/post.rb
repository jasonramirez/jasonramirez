class Post < ActiveRecord::Base
  has_and_belongs_to_many :hashtags

  validates :title, presence: true

  extend FriendlyId
  friendly_id :title, use: :slugged
  
  after_save :ping_sitemap_if_published, if: :saved_change_to_published?

  def parsed_body
    MarkdownParser.new(self.body).markdown_to_html
  end

  def pretty_published_date
    published_date.strftime("%-m/%-d/%y")
  end

  def published_state_class
    published || "not-published"
  end

  def published_state
    published ? "Published" : "Not Published"
  end

  def should_generate_new_friendly_id?
    title_changed?
  end
  
  private
  
  def ping_sitemap_if_published
    return unless published?
    
    # Use delayed job to ping search engines asynchronously
    SitemapPingJob.perform_later if defined?(SitemapPingJob)
  end
end
