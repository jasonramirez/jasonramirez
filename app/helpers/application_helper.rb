module ApplicationHelper
  def themed_stylesheet
    return "application_#{cookies[:theme]}"
  end
end
