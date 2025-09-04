require "rails_helper"

feature "Admin edits post", js: true do
  context "from the post's page" do
    it "successfully updates the post and shows a success flash." do
      post = create(:post)
      sign_in_admin

      visit edit_admins_post_path(post)

      fill_form(:post, title: "New Title")

      page.find("#save_post").click

      expect(page).to have_text t("admins.flash.updated")
      visit admins_posts_path

      expect(page).to have_text "New Title"
    end

    it "allows page refresh after title change without 505 error" do
      post = create(:post, title: "Original Title")
      sign_in_admin

      visit edit_admins_post_path(post)

      fill_form(:post, title: "Updated Title")

      page.find("#save_post").click

      expect(page).to have_text t("admins.flash.updated")

      # Refresh the page - this should work without a 505 error
      page.refresh

      # Should still be on the edit page with the updated title
      expect(page).to have_field("post[title]", with: "Updated Title")
      expect(page).to have_current_path(edit_admins_post_path(post.reload))
    end

    it "handles draft post title change and page refresh" do
      sign_in_admin

      # Create a draft post (simulating clicking "New Post" from index)
      visit admins_posts_path
      page.find("#new_post_link").click

      # Should be on edit page with "Draft" title
      expect(page).to have_field("post[title]", with: "Draft")

      # Change the title
      fill_form(:post, title: "My New Post Title")

      page.find("#save_post").click

      expect(page).to have_text t("admins.flash.updated")

      # Refresh the page - this should work without a 505 error
      page.refresh

      # Should still be on the edit page with the updated title
      expect(page).to have_field("post[title]", with: "My New Post Title")
    end
  end

  private

  def sign_in_admin
    admin = create(:admin)
    login_as admin, scope: :admin
  end
end
