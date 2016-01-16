require "rails_helper"

RSpec.feature "Guest views works" do
  context "at the root domain" do
    it "shows the works" do
      visit "/"

      expect(page).to have_css "img.work"
    end
  end
end
