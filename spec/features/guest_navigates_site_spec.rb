require "rails_helper"

RSpec.feature "Guest navigates site" do
  context "from the landing page" do
    describe "clicking a project" do
      it "takes you to that project's page" do
        visit root_path

        page.find(:xpath, ".//a[@href='case_studies/piggy']").click

        expect(page).to have_text "Piggy"
      end
    end
  end

  context "from a projects page" do
    describe "clicking to home button" do
      it "takes you to the home page" do
        visit "case_studies/piggy"

        within ".site-header" do
          click_link t("navigation.home")
        end

        expect(page).to have_css "body.welcome"
      end
    end
  end
end
