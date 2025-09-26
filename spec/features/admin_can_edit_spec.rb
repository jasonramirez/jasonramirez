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

      expect(page).to have_text t("admins.posts.index.all_posts")
    end
  end

  context "post from the post itself when logged in" do
    it "takes them directly to the post." do
      sign_in_admin
      post = create(:post, title: "Post One", published: true)

      visit post_path(post)
      
      # Wait for page to load
      expect(page).to have_text "Post One"

      page.find("#post_edit_link").click

      # Open the drawer to see the Post Details
      page.find("[data-js-drawer-open-trigger]").click
      
      # Wait for the drawer to open and show the Post Details
      expect(page).to have_css("h2", text: "Post Details", wait: 5)
    end
  end
end
