require "rails_helper"

RSpec.feature "Admin deletes post" do
  before(:each) do
    # Ensure clean state before each test
    Post.destroy_all
    Hashtag.destroy_all
    Admin.destroy_all
  end

  context "from the posts list" do
    it "removes the post", js: true do
      sign_in_admin
      post_one = create(:post, title: "This is the post title")
      post_two = create(:post, title: "This is post 2")

      visit admins_posts_path
      
      # Verify we start with 2 posts
      expect(page).to have_text "2 posts"
      expect(page).to have_text "This is the post title"
      expect(page).to have_text "This is post 2"
      
      # Click the delete button for the first post
      within first(".admin-post-item") do
        click_button
      end
      
      # Accept the confirmation dialog
      page.driver.browser.switch_to.alert.accept

      # Verify the post was deleted
      expect(page).to have_text "1 posts"
      expect(page).not_to have_text "This is the post title"
      expect(page).to have_text "This is post 2"
      
      # Verify we're still on the posts index page
      expect(page).to have_current_path(admins_posts_path)
    end
  end
end