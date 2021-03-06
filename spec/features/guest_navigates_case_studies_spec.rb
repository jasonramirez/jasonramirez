require "rails_helper"

RSpec.feature "Guest navigations case studies" do
  context "from the footer navigation of the case studies detail page" do
    describe "the next button" do
      it "goes to the next work" do
        visit "case_studies/piggy"

        within ".case-study-footer" do
          click_link "Next"
        end

        expect(page).to have_text "Penner"
      end
    end

    describe "the previous button" do
      it "goes to the previous work" do
        visit "case_studies/tinysplash"

        within ".case-study-footer" do
          click_link "Previous"
        end

        expect(page).to have_text "Piggy"
      end
    end
  end
end
