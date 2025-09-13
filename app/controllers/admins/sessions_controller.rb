class Admins::SessionsController < Devise::SessionsController
  def new
    # Don't clear flash messages - we want to show authentication errors
    super
  end
end
