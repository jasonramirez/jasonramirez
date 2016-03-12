require "rails_helper"

RSpec.feature "Guest navigates site" do
  context "from the landing page" do
    describe "clicking a project" do
      it "takes you to that project's page" do
        visit root_path

        page.find(:xpath, ".//a[@href='works/piggy']").click

        expect(page).to have_css "body.works-piggy"
      end
    end

    describe "clicking the process link in the nav" do
      it "takes you to that process page" do
        visit root_path

        within ".site-header" do
          click_link t("navigation.process")
        end

        expect(page).to have_text t("process.show.title")
      end
    end
  end

  context "from a projects page" do
    describe "clicking to home button" do
      it "takes you to the home page" do
        visit works_piggy_path

        within ".site-header" do
          click_link t("navigation.works")
        end

        expect(page).to have_css "body.welcome"
      end
    end
  end
end
