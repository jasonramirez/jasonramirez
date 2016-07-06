require "rails_helper"

RSpec.feature "Guest navigations case studies" do
  context "from the hero navigation of the case studies detail page" do
    describe "the next button" do
      it "goes to the next work" do
        visit_piggy

        page.first(".case-study-page-navigation--left").click

        expect(page).to have_text "Penner"
      end
    end

    describe "the previous button" do
      it "goes to the previous work" do
        visit_piggy

        page.first(".case-study-page-navigation--right").click

        expect(page).to have_text "Tinysplash"
      end
    end
  end

  context "from the footer navigation of the case studies detail page" do
    describe "the next button" do
      it "goes to the next work" do
        visit_piggy

        within ".case-study-footer" do
          click_link "Next"
        end

        expect(page).to have_text "Penner"
      end
    end

    describe "the previous button" do
      it "goes to the previous work" do
        visit_piggy

        within ".case-study-footer" do
          click_link "Previous"
        end

        expect(page).to have_text "Tinysplash"
      end
    end
  end

  def visit_piggy
    visit "case_studies/piggy"
  end
end
