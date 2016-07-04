require "rails_helper"

RSpec.feature "Guest navigations works" do
  context "from the hero navigation of the works detail page" do
    describe "the next button" do
      it "goes to the next work" do
        visit works_piggy_path

        page.first(".work-page-navigation--left").click

        expect(page).to have_text "Penner"
      end
    end

    describe "the previous button" do
      it "goes to the previous work" do
        visit works_piggy_path

        page.first(".work-page-navigation--right").click

        expect(page).to have_text "Tinysplash"
      end
    end
  end

  context "from the footer navigation of the works detail page" do
    describe "the next button" do
      it "goes to the next work" do
        visit works_piggy_path

        within ".work-footer" do
          click_link "Next"
        end

        expect(page).to have_text "Penner"
      end
    end

    describe "the previous button" do
      it "goes to the previous work" do
        visit works_piggy_path

        within ".work-footer" do
          click_link "Previous"
        end

        expect(page).to have_text "Tinysplash"
      end
    end
  end
end
