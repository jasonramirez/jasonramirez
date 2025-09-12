require "rails_helper"

feature "Guest attempts to view resume" do
  scenario "is redirected to admin login" do
    visit "/admins/documents/resume"

    expect(current_path).to eq("/admins/sign_in")
  end
end
