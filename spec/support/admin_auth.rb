# Helper methods for admin authentication in tests
module AdminAuth
  def sign_in_admin(admin = nil)
    admin ||= create(:admin)
    
    # Use different authentication methods based on test type
    if respond_to?(:login_as)
      # Feature tests use Warden
      login_as admin, scope: :admin
    else
      # Request/Controller tests use HTTP
      post admin_session_path, params: { admin: { email: admin.email, password: admin.password } }
    end
    
    admin
  end

  def sign_out_admin
    if respond_to?(:logout)
      # Feature tests use Warden
      logout(:admin)
    else
      # Request/Controller tests use HTTP
      delete admin_session_path
    end
  end
end

RSpec.configure do |config|
  config.include AdminAuth, type: :request
  config.include AdminAuth, type: :controller
  config.include AdminAuth, type: :feature
end
