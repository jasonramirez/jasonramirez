require "rails_helper"

feature "Admin previews post" do
  context "even if it's not published" do
    it "shows the post" do
      sign_in_admin
      create(:post)
      post = create(:post, long_title: "Post title", published: "false")

      visit post_path(post)

      expect(page).to have_text "Post title"
    end
  end

  private

  def sign_in_admin
    admin = create(:admin)
    login_as admin, scope: :admin
  end
end
