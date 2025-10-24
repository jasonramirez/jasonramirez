class MarkdownParser
  require "redcarpet"

  def initialize(markdown)
    @markdown = markdown
  end

  def markdown_to_html
    # Return empty string if markdown is nil or empty
    return "" if @markdown.nil? || @markdown.empty?
    
    # Sanitize HTML output to prevent XSS
    sanitize_html(processor.render(@markdown))
  end

  private

  def sanitize_html(html)
    # Use Rails' built-in sanitizer to allow safe HTML tags
    ActionController::Base.helpers.sanitize(
      html,
      tags: %w[p br strong em code pre blockquote ul ol li h1 h2 h3 h4 h5 h6 a hr div span],
      attributes: %w[class id style href target rel]
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
      safe_links_only: true
    }
  end

  def extensions
    {
      autolink: true,
      fenced_code_blocks: true,
      highlight: true,
      tables: true,
      strikethrough: true,
      superscript: true,
      underline: true,
      quote: true,
      footnotes: true,
      no_intra_emphasis: true,
      space_after_headers: true,
      hard_wrap: true
    }
  end
end
