require "rails_helper"

RSpec.feature "Guest navigates with Turbo" do
  it "loads Turbo on the page" do
    visit root_path

    expect(page.evaluate_script("typeof window.Turbo")).to eq "object"
    expect(page.evaluate_script("window.Turbo.session.drive")).to be true
  end

  it "follows header links without a full page reload" do
    visit root_path
    page.execute_script("window.turboNavigationMarker = true")

    within ".navigation-primary" do
      click_link t("navigation.philosophy")
    end

    expect(page).to have_current_path philosophy_path
    expect(page).to have_text "My principles influence"
    expect(page.evaluate_script("window.turboNavigationMarker")).to be true
  end
end
