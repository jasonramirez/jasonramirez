require "rails_helper"

RSpec.feature "Admin deletes post" do
  context "from the posts list" do
    it "removes the post" do
      sign_in_admin
      post_one = create(:post, title: "This is the post title")
      post_two = create(:post, title: "This is post 2")

      visit admins_posts_path
      first(".admin-post-item").click_link(t("admins.posts.index.delete_post"))

      expect(page).to_not have_text post_one.title
      expect(page).to have_text post_two.title
    end
  end

  def sign_in_admin
    admin = create(:admin)
    login_as admin, scope: :admin
  end
end
