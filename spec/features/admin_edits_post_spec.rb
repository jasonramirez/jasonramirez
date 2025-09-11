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

    it "successfully updates post content (post_markdown)" do
      post = create(:post, post_markdown: "# Original Content")
      sign_in_admin

      visit edit_admins_post_path(post)

      # Update the markdown content
      fill_in "post[post_markdown]", with: "# Updated Content\n\nThis is **new** markdown content."

      page.find("#save_post").click

      expect(page).to have_text t("admins.flash.updated")

      # Verify the content was saved
      post.reload
      expect(post.post_markdown).to eq("# Updated Content\n\nThis is **new** markdown content.")
      expect(post.post_text).to include("Updated Content")
      expect(post.post_text).to include("new")
    end

    it "updates both title and content simultaneously" do
      post = create(:post, title: "Original Title", post_markdown: "# Original Content")
      sign_in_admin

      visit edit_admins_post_path(post)

      fill_form(:post, title: "Updated Title")
      fill_in "post[post_markdown]", with: "# Updated Content\n\nBoth title and content changed."

      page.find("#save_post").click

      expect(page).to have_text t("admins.flash.updated")

      # Verify both fields were saved
      post.reload
      expect(post.title).to eq("Updated Title")
      expect(post.post_markdown).to eq("# Updated Content\n\nBoth title and content changed.")
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

    it "updates preview button URL when title changes" do
      post = create(:post, title: "Original Title")
      sign_in_admin

      visit edit_admins_post_path(post)

      # Get the original preview URL
      original_preview_url = find("#preview_post")[:href]

      # Change the title
      fill_form(:post, title: "New Title")

      page.find("#save_post").click

      expect(page).to have_text t("admins.flash.updated")

      # Check that the preview button URL has been updated
      new_preview_url = find("#preview_post")[:href]
      expect(new_preview_url).to_not eq(original_preview_url)
      expect(new_preview_url).to include("new-title")
    end

    it "updates form action URL when title changes" do
      post = create(:post, title: "Original Title")
      sign_in_admin

      visit edit_admins_post_path(post)

      # Get the original form action URL
      original_form_action = find("form")[:action]

      # Change the title
      fill_form(:post, title: "New Title")

      page.find("#save_post").click

      expect(page).to have_text t("admins.flash.updated")

      # Check that the form action URL has been updated
      new_form_action = find("form")[:action]
      expect(new_form_action).to_not eq(original_form_action)
      expect(new_form_action).to include("new-title")
      expect(new_form_action).to_not include("/edit")
    end
  end

  private

  def sign_in_admin
    admin = create(:admin)
    login_as admin, scope: :admin
  end
end
