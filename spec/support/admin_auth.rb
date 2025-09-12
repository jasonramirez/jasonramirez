# Helper methods for admin authentication in tests
module AdminAuth
  def sign_in_admin(admin = nil)
    admin ||= create(:admin)
    post admin_session_path, params: { admin: { email: admin.email, password: admin.password } }
    admin
  end

  def sign_out_admin
    delete admin_session_path
  end
end

RSpec.configure do |config|
  config.include AdminAuth, type: :request
  config.include AdminAuth, type: :controller
  config.include AdminAuth, type: :feature
end
