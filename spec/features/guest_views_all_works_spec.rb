require "rails_helper"

RSpec.feature "Guest views all works" do
  context "on the index page" do
    it "shows the thumbnail" do
      visit "/"

      expect(page).to have_css "li.tinysplash"
      expect(page).to have_css "li.piggy"
    end
  end
end
