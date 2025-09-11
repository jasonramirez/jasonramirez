require "rails_helper"

feature "Guest attempts to view resume" do
  scenario "is redirected to admin login" do
    visit "/admins/documents/resume"

    expect(page).to have_text("You need to sign in or sign up before continuing")
    expect(current_path).to eq("/admins/sign_in")
  end
end
