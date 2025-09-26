require "rails_helper"

feature "Admin can edit" do
  before(:each) do
    # Ensure clean state before each test
    Post.destroy_all
    Hashtag.destroy_all
    Admin.destroy_all
  end

  context "when logged in, and by clicking the admin button" do
    it "takes them to the admin posts index page." do
      sign_in_admin

      visit root_path

      page.find("#admin_edit_link").click

      expect(page).to have_text "Posts"
    end
  end

  context "post from the post itself when logged in" do
    it "allows admin to edit post directly from posts index" do
      sign_in_admin
      post = create(:post, title: "Post One", published: true)

      # Go to posts page
      visit admins_posts_path
      expect(page).to have_text "Post One"

      # Click on the post title to go directly to edit page
      click_link "Post One"

      # Verify we're taken to the edit page
      expect(page).to have_current_path(edit_admins_post_path(post))
      expect(page).to have_text "Post One"
    end
  end
end