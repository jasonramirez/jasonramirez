require "rails_helper"

RSpec.feature "Guest navigates site" do
  describe "by clicking home" do
    it "take the user to the landing page" do
      visit root_path

      click_link "tinysplash"
      click_link t("navigation.works")

      expect(page).to have_css "ul.works"
    end
  end
end
