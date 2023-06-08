require "rails_helper"

feature "Guest views resume" do
  scenario "from landing page" do
    visit "/resume"

    expect(page).to have_text("Work History")
  end
end
