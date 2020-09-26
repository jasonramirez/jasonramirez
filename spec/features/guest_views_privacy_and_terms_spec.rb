require "rails_helper"

RSpec.feature "Guest views privacy and terms" do
  scenario "from the footer" do
    visit root_path

    within ".site-footer" do
      click_on t("navigation.privacy_and_terms")
    end

    within ".content" do
      expect(page).to have_text "Privacy & Terms"
    end
  end
end
