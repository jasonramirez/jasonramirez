require "rails_helper"

feature "Admin adds hashtag" do
  context "from the navigation" do
    it "shows a list of all hashtags" do
      sign_in_admin
      visit admins_hashtags_path

      click_on t("admins.navigation.new_hashtag")
      fill_new_hashtag_form

      expect(page).to have_text t("admins.flash.created")
    end
  end

  context "from the new hashtags page scucessfully" do
    it "shows a success message" do
      sign_in_admin
      visit new_admins_hashtag_path

      fill_new_hashtag_form

      expect(page).to have_text t("admins.flash.created")
    end
  end

  context "from the new hashtags page not successfully" do
    it "shows a failure message" do
      sign_in_admin
      visit new_admins_hashtag_path

      fill_form(:hashtag, :new, label: "")
      click_button t("admins.hashtags.form.save")

      expect(page).to have_text t("admins.flash.failed")
    end
  end

  def fill_new_hashtag_form
    fill_form(:post, label: "hashtagone")
    click_button t("admins.hashtags.form.save")
  end

  def sign_in_admin
    admin = create(:admin)
    login_as admin, scope: :admin
  end
end
