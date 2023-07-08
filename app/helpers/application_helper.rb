module ApplicationHelper
  def themed_stylesheet
    return "application_#{theme}"
  end

  def theme
    if cookies[:theme].blank?
      cookies[:theme] = "dark"
    else
      cookies[:theme]
    end
  end
end
