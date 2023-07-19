require "rails_helper"

feature "Admin previews post" do
  context "even if it's not published" do
    it "shows the post" do
      sign_in_admin
      create(:post)
      post = create(:post, published: "false")

      visit post_path(post)

      expect(page).to have_text post.title
    end
  end

  private

  def sign_in_admin
    admin = create(:admin)
    login_as admin, scope: :admin
  end
end
