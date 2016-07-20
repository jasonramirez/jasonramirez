require "rails_helper"

RSpec.feature "Admin deletes post" do
  context "from the posts list" do
    it "removes the post" do
      post = create(:post, title: "This is the post title")

      visit admin_posts_path
      click_on t("admin.posts.index.delete_post")

      expect(page).to_not have_text post.title
    end
  end
end
