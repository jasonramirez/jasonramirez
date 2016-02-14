require "rails_helper"

RSpec.feature "Guest views all works" do
  context "on the index page" do
    it "shows the thumbnail" do
      visit "/"

      works.each do |work|
        expect(page).to have_css "##{work}"
      end
    end
  end

  def works
    [
      "frida_and_fred",
      "ouch",
      "penner",
      "piggy",
      "project_underdog",
      "repor",
      "tinysplash",
    ]
  end
end
