module ThemeHelper
  # Theme switching is now handled by JavaScript
  # This helper is kept for backward compatibility
  
  def theme_stylesheet
    "application_#{theme}"
  end
  
  def theme_content
    theme_color
  end
  
  def stylesheet
    stylesheet_link_tag theme_stylesheet
  end
  
  private
  
  def theme
    cookies[:theme] || 'dark'
  end
  
  def theme_color
    case theme
    when 'light'
      '#fffaed'
    else
      '#181923'
    end
  end
end
