require "rails_helper"

RSpec.feature "Guest views posts" do
  describe "as a list" do
    it "shows the list of articles" do
      visit root_path

      click_link t("navigation.posts")

      expect(page).to have_text t("titles.posts")
    end
  end
end
