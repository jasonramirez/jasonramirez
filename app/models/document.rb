class Document < ActiveRecord::Base
  extend FriendlyId
  friendly_id :title, use: :slugged

  validates :title, presence: true

  def parsed_content
    return "" if content_markdown.blank?
    MarkdownParser.new(content_markdown).markdown_to_html
  end

  def should_generate_new_friendly_id?
    title_changed? || super
  end
end

