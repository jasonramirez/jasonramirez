module ApplicationHelper
  # Include other helper modules to maintain backward compatibility
  include ThemeHelper
  include SvgHelper
  include KnowledgeHelper
  include FlashesHelper

  def format_duration(seconds)
    return "0:00" if seconds.nil? || seconds <= 0
    
    minutes = seconds / 60
    remaining_seconds = seconds % 60
    
    sprintf("%d:%02d", minutes, remaining_seconds)
  end

  def parse_framework_links(content)
    return content if content.blank?
    
    # Use MarkdownParser for full markdown processing including paragraphs, lists, etc.
    markdown_parser = MarkdownParser.new(content)
    processed_content = markdown_parser.markdown_to_html
    
    # Convert markdown links [text](url) to Rails link_to helpers for framework links
    processed_content = processed_content.gsub(/<a href="([^"]+)"[^>]*>([^<]+)<\/a>/) do |match|
      url = $1
      link_text = $2
      # Check if this is a framework link (internal post link)
      if url.start_with?('/posts/')
        link_to(link_text, url, target: '_blank', class: 'framework-link')
      else
        match # Keep original link for external URLs
      end
    end
    
    processed_content
  end

  private

  def process_basic_markdown(content)
    # Convert **bold** to <strong>
    content = content.gsub(/\*\*([^*]+)\*\*/, '<strong>\1</strong>')
    
    # Convert *italic* to <em> (but avoid interfering with **bold**)
    content = content.gsub(/(?<!\*)\*([^*]+)\*(?!\*)/, '<em>\1</em>')
    
    # Convert `code` to <code>
    content = content.gsub(/`([^`]+)`/, '<code>\1</code>')
    
    content
  end
end
