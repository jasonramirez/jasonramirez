module ApplicationHelper
  def theme_content
    theme_color
  end

  def theme_stylesheet
    "application_#{theme}"
  end

  private

  def theme
    cookies[:theme] ||= "dark"
  end

  def theme_color
    theme == "dark" ? "#181923" : "#fffaed"
  end
end
