class MarkdownParser
  require "redcarpet"

  def initialize(markdown)
    @markdown = markdown
  end

  def markdown_to_html
    # Return empty string if markdown is nil or empty
    return "" if @markdown.nil? || @markdown.empty?
    
    # Preprocess markdown to ensure lists are recognized after HTML tags
    processed_markdown = preprocess_markdown(@markdown)
    
    # Sanitize HTML output to prevent XSS
    sanitize_html(processor.render(processed_markdown))
  end

  private

  def sanitize_html(html)
    # Use Rails' built-in sanitizer to allow safe HTML tags
    ActionController::Base.helpers.sanitize(
      html,
      tags: %w[p br strong em code pre blockquote ul ol li h1 h2 h3 h4 h5 h6 label div section],
      attributes: %w[class id style]
    )
  end

  def processor
    Redcarpet::Markdown.new(renderer, extensions)
  end

  def renderer
    RougeRenderer.new(render_options)
  end

  def render_options
    {
      filter_html: false,
      no_images: false,
      no_links: false,
      safe_links_only: true
    }
  end

  def extensions
    {
      autolink: true,
      fenced_code_blocks: true,
      highlight: true,
      tables: true,
    }
  end

  def preprocess_markdown(markdown)
    # Ensure lists following HTML tags (like <label>) are on a new line
    # This regex finds patterns like "<label>...</label>\n- " or "<label>...</label>:\n- "
    # and ensures there's a blank line before the list starts
    markdown.gsub(/(<[^>]+>)\s*:?\s*\n(\s*- )/, "\\1\n\n\\2")
  end
end
