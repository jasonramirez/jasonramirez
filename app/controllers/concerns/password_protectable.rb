module PasswordProtectable
  extend ActiveSupport::Concern

  included do
    before_action :check_password_protection
  end

  private

  def check_password_protection
    return if session[:unlocked]
    
    store_location_for_password_protection
    redirect_to password_protection_unlock_path(return_to: request.fullpath)
  end

  def store_location_for_password_protection
    session[:return_to] = request.fullpath
  end
end
