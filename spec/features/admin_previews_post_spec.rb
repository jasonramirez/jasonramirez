require "rails_helper"

feature "Admin previews post" do
  before(:each) do
    # Ensure clean state before each test
    Post.destroy_all
    Hashtag.destroy_all
    Admin.destroy_all
  end

  context "when it is published" do
    it "shows the post" do
      sign_in_admin
      post = create(:post, published: true)

      visit post_path(post)

      expect(page).to have_text post.title
    end
  end

  context "even if it's not published" do
    it "shows the post" do
      sign_in_admin
      post = create(:post, published: false)

      visit post_path(post)

      expect(page).to have_text post.title
    end
  end

  context "with nil body" do
    it "shows the post without error" do
      sign_in_admin
      post = create(:post, post_markdown: nil)

      visit post_path(post)

      expect(page).to have_text post.title
      expect(page).to_not have_text "TypeError"
    end
  end

  context "draft post with no body content" do
    it "allows preview without error" do
      sign_in_admin
      
      # Create a draft post (simulating the "New Post" flow)
      visit admins_posts_path
      page.find("#new_post_link").click
      
      # Should be on edit page with "Draft" title
      expect(page).to have_field("post[title]", with: "Draft")
      
      # Try to preview the post before adding any body content
      page.find("#preview_post").click
      
      # Should show the post without a TypeError
      expect(page).to have_text "Draft"
      expect(page).to_not have_text "TypeError"
    end
  end

end
