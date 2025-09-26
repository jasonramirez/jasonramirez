require "rails_helper"

feature "Admin deletes hashtag", js: true do
  before(:each) do
    # Ensure clean state before each test
    Post.destroy_all
    Hashtag.destroy_all
    Admin.destroy_all
  end

  context "from the hashtags list" do
    it "requires a replacement hashtag to be selected" do
      # THIS TEST SEEMS TO BREAK:
      # rspec ./spec/features/admin_can_edit_spec.rb:17 #
      sign_in_admin
      hashtag_one = create(:hashtag, label: "hashtagone")
      hashtag_two = create(:hashtag, label: "hashtagtwo")

      visit admins_hashtags_path
      first(".admin-post-item__actions a").click
      
      # Try to confirm deletion without selecting a replacement
      accept_alert "Please select a hashtag to replace with." do
        click_button "Confirm"
      end
      
      # Hashtag should still be there
      expect(page).to have_text hashtag_one.label
    end

    it "replaces hashtag with another one when replacement is selected" do
      sign_in_admin
      old_hashtag = create(:hashtag, label: "oldhashtag")
      new_hashtag = create(:hashtag, label: "newhashtag")
      post = create(:post)
      post.hashtags << old_hashtag

      visit admins_hashtags_path
      
      # Click delete button for the old hashtag
      within(".admin-post-item", text: old_hashtag.label) do
        find(".admin-post-item__actions a").click
      end

      # Select replacement hashtag in modal
      select new_hashtag.label, from: "replacement-hashtag"
      
      # Confirm deletion
      click_button "Confirm"

      # Check that old hashtag is gone
      expect(page).to_not have_text old_hashtag.label
      
      # Check that post now has the new hashtag
      post.reload
      expect(post.hashtags).to include(new_hashtag)
      expect(post.hashtags).to_not include(old_hashtag)
    end
  end
end
