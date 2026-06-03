module ApplicationHelper
  # Include other helper modules to maintain backward compatibility
  include ThemeHelper
  include SvgHelper
  include FlashesHelper

  # Renders a plain-text transcript file as <p> paragraphs (used by the
  # custom audio player on works/posts).
  def read_transcript_file(file_path)
    full_path = Rails.root.join('app', 'assets', file_path)
    return nil unless File.exist?(full_path)

    content = File.read(full_path)
    paragraphs = content.split(/\n\s*\n/).reject(&:blank?)

    paragraphs.map do |paragraph|
      content_tag(:p, paragraph.strip)
    end.join.html_safe
  end
end
