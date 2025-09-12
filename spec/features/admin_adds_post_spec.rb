require "rails_helper"

feature "Admin adds post" do
  context "by clicking the add new posts button on the all posts page" do
    it "successfully creates the post and shows a success flash." do
      sign_in_admin
      visit admins_posts_path

      page.find("#new_post_link").click

      # Fill out the form
      fill_in "Title", with: "Test Post"
      fill_in "Body", with: "This is a test post"
      click_button "Save"

      expect(page).to have_field("post-id", with: Post.all.first.id)
      expect(page).to have_field("post-url", with: /draft/i)
      expect(page).to have_text t("admins.flash.created")
    end
  end

  context "then previews it from the post even if its not published" do
    it "shows the post." do
      create(:post, title: "Post One", published: false)
      sign_in_admin
      visit admins_posts_path

      within ".admin-post-item" do
        click_link "Post One"
      end
      page.find("#preview_post").click

      expect(page).to have_text  "Post One"
    end
  end

  private

  def sign_in_admin
    admin = create(:admin)
    login_as admin, scope: :admin
  end
end
