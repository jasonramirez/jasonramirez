require "rails_helper"

feature "Admin adds hashtag" do
  before(:each) do
    # Ensure clean state before each test
    Post.destroy_all
    Hashtag.destroy_all
    Admin.destroy_all
  end

  context "from the navigation" do
    it "shows a list of all hashtags" do
      sign_in_admin
      visit admins_hashtags_path

      page.find("#new_hashtag_link").click
      fill_new_hashtag_form

      expect(page).to have_css "input[value='#hashtagone']"
      expect(page).to have_text t("admins.flash.created")
    end
  end

  context "from the new hashtags page sucessfully" do
    it "shows a success message" do
      sign_in_admin
      visit new_admins_hashtag_path

      fill_new_hashtag_form

      expect(page).to have_css "input[value='#hashtagone']"
      expect(page).to have_text t("admins.flash.created")
    end
  end

  context "from the new hashtags page sucessfully" do
    it "strips out special characters and adds a #" do
      sign_in_admin
      visit new_admins_hashtag_path

      fill_form(:hashtag, :new, label: "hashtagone - _ # ")
      click_button t("admins.hashtags.form.save")

      expect(page).to have_css "input[value='#hashtagone']"
      expect(page).to have_text t("admins.flash.created")
    end
  end

  context "from the new hashtags page not successfully" do
    it "shows a failure message" do
      sign_in_admin
      visit new_admins_hashtag_path

      fill_form(:hashtag, :new, label: "")
      click_button t("admins.hashtags.form.save")

      expect(page).to_not have_css "input[value='#hashtagone']"
      expect(page).to have_text t("admins.flash.failed")
    end
  end

  def fill_new_hashtag_form
    fill_form(:hashtag, label: "hashtagone")
    click_button t("admins.hashtags.form.save")
  end
end
