class Admins::SessionsController < Devise::SessionsController
  def new
    # Clear any existing flash messages when showing the login page
    flash.clear
    super
  end
end
