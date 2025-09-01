class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.

  protect_from_forgery with: :exception

  
  # Custom error handling for Devise
  rescue_from ActionController::InvalidAuthenticityToken do
    flash[:alert] = "Session expired. Please try logging in again."
    redirect_to new_admin_session_path
  end
end
