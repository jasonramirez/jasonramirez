require "rails_helper"

RSpec.feature "Guest views each case studies deatils" do
  describe "tinysplash" do
    it "shows the details" do
      visit "/"

      click_link "Tinysplash"

      expect(page).to have_text "Tinysplash"
    end
  end

  describe "piggy" do
    it "shows the details" do
      visit "/"

      click_link "Piggy"

      expect(page).to have_text "Piggy"
    end
  end
end
