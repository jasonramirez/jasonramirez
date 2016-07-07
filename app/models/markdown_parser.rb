class MarkdownParser
  require "redcarpet"

  def initialize(markdown)
    @markdown = markdown
  end

  def markdown_to_html
    processor.render(@markdown).html_safe
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
      fenced_code_blocks: true,
      tables: true,
      highlight: true,
    }
  end
end
