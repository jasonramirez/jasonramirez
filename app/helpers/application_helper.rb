module ApplicationHelper
  def theme_content
    theme_color
  end

  def stylesheet
    stylesheet_link_tag(
      theme_stylesheet,
      media: "all",
      "data-turbo-track": "reload"
    )
  end

  def theme_stylesheet
    "application_#{theme}"
  end

  def read_transcript_file(file_path)
    full_path = Rails.root.join('app', 'assets', file_path)
    return nil unless File.exist?(full_path)
    
    content = File.read(full_path)
    paragraphs = content.split(/\n\s*\n/).reject(&:blank?)
    
    paragraphs.map do |paragraph|
      content_tag(:p, paragraph.strip)
    end.join.html_safe
  end

  private

  def theme
    cookies[:theme] ||= "dark"
  end

  def theme_color
    theme == "dark" ? "#181923" : "#fffaed"
  end
end
