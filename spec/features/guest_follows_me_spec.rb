require "rails_helper"

RSpec.feature "Guest follows me" do
  context "succesfully" do
    it "shows a success flash message" do
      visit new_follower_path

      fill_form_and_submit(:follower, :new, {email: "user@example.com"});

      expect(page).to have_text "Success"
    end
  end

  context "failure" do
    it "shows a failure flash message" do
      visit new_follower_path

      fill_form_and_submit(:follower, :new, {email: ""})

      expect(page).to have_text "Failure"
    end
  end
end
