require "rails_helper"

RSpec.feature "Guest views works" do
  context "on the index page" do
    it "shows the thumbnail" do
      visit "/"

      expect(page).to have_css "img.work"
    end
  end

  context "on the show page" do
    it "shows the details" do
      visit "/"

      click_link "tinysplash"

      expect(page).to have_text "Tinysplash"
    end
  end
end
