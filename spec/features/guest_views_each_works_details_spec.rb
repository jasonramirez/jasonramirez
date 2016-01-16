require "rails_helper"

RSpec.feature "Guest views each works deatils" do
  describe "tinysplash" do
    it "shows the details" do
      visit "/"

      click_link "tinysplash"

      expect(page).to have_text "Tinysplash"
    end
  end

  describe "piggy" do
    it "shows the details" do
      visit "/"

      click_link "piggy"

      expect(page).to have_text "Piggy"
    end
  end
end
