class Post < ActiveRecord::Base
  has_and_belongs_to_many :hashtags

  validates :title, presence: true

  extend FriendlyId
  friendly_id :title, use: :slugged
  
  after_save :ping_sitemap_if_published, if: :saved_change_to_published?

  def parsed_body
    MarkdownParser.new(self.post_markdown).markdown_to_html
  end

  # Generate plain text version of the markdown content
  def generate_post_text
    return '' if post_markdown.blank?
    
    # Parse markdown to HTML first, then strip HTML tags for plain text
    html_content = MarkdownParser.new(post_markdown).markdown_to_html
    
    # Remove HTML tags and clean up whitespace
    plain_text = html_content.gsub(/<[^>]*>/, ' ')
                            .gsub(/\s+/, ' ')
                            .strip
    
    plain_text
  end

  # Automatically populate post_text when post_markdown changes
  before_save :update_post_text, if: :post_markdown_changed?

  private

  def update_post_text
    self.post_text = generate_post_text
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
