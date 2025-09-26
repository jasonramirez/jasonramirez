require "rails_helper"

feature "Admin edits hashtag" do
  before(:each) do
    # Ensure clean state before each test
    Post.destroy_all
    Hashtag.destroy_all
    Admin.destroy_all
  end

  context "from the hashtags list by clicking on the hashtag" do
    it "updates the hashtag" do
      sign_in_admin
      hashtag = create(:hashtag, label: "hashtag")

      visit admins_hashtags_path
      click_on hashtag.label
      fill_in "Label", with: "newhashtag"
      click_button "Save"

      expect(page).to have_selector("input[value='#newhashtag']")
      expect(page).to have_text t("admins.flash.updated")
    end
  end

  context "from the hashtaglist by clicking the edit button" do
    it "updates the hashtag" do
      sign_in_admin
      hashtag = create(:hashtag, label: "testhashtag")

      visit admins_hashtags_path
      click_on hashtag.label
      fill_in "Label", with: "#newhashtag"
      click_button "Save"

      expect(page).to have_selector("input[value='#newhashtag']")
      expect(page).to have_text t("admins.flash.updated")
    end
  end

end
