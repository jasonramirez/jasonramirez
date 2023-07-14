require "rails_helper"

feature "Admin edits hashtag" do
  context "from the hashtags list clicking on the hashtag" do
    it "updates the hashtag" do
      sign_in_admin
      hashtag = create(:hashtag, label: "hashtag")

      visit admins_hashtags_path
      click_on hashtag.label
      fill_form_and_submit(:hashtag, :edit, label: "newhashtag")

      expect(page).to have_selector("input[value='newhashtag']")
      expect(page).to have_text t("admins.flash.updated")
    end
  end

  context "from the hashtaglist using the edit button" do
    it "updates the hashtag" do
      sign_in_admin
      create(:hashtag)

      visit admins_hashtags_path
      within(find(".admin-post-item:first-of-type")) do
        click_on t("admins.hashtags.index.edit_hashtag")
      end
      fill_form_and_submit(:hashtag, :edit, label: "newhashtag")

      expect(page).to have_selector("input[value='newhashtag']")
      expect(page).to have_text t("admins.flash.updated")
    end
  end

  private

  def sign_in_admin
    admin = create(:admin)
    login_as admin, scope: :admin
  end
end
