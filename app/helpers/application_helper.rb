module ApplicationHelper
  # Include other helper modules to maintain backward compatibility
  include ThemeHelper
  include SvgHelper
  include KnowledgeHelper
  include FlashesHelper

  def parse_framework_links(content)
    return content if content.blank?
    
    # First convert markdown links [text](url) to HTML links
    processed_content = content.gsub(/\[([^\]]+)\]\(([^)]+)\)/) do |match|
      link_text = $1
      url = $2
      link_to(link_text, url, target: '_blank', class: 'framework-link')
    end
    
    # Then convert basic markdown formatting
    processed_content = process_basic_markdown(processed_content)
    
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
