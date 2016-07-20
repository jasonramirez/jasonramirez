require "rails_helper"

RSpec.feature "Admin edits post" do
  context "from the posts list" do
    it "shows a list of all posts" do
      sign_in_admin
      post = create(:post, title: "Post Title")

      visit admin_posts_path
      click_on post.title
      fill_form_and_submit(:post, :edit, title: "New Title")

      expect(page).to have_selector("input[value='New Title']")
      expect(page).to have_text t("admin.flash.updated")
    end
  end

  context "from the post" do
    it "shows a success message" do
      sign_in_admin
      post = create(:post)
      visit edit_admin_post_path(post)

      fill_form_and_submit(:post, :edit, title: "New Title")

      expect(page).to have_selector("input[value='New Title']")
      expect(page).to have_text t("admin.flash.updated")
    end
  end

  def sign_in_admin
    admin = create(:admin)
    login_as admin, scope: :admin
  end
end
