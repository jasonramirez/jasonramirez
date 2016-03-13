require "rails_helper"

RSpec.feature "Guest views all works" do
  context "on the index page" do
    it "has thumbnail links to each work" do
      visit "/"

      works.each do |work|
        expect(page).to have_css "a[href='works/#{work}']"

        page.find(:xpath, ".//a[@href='works/#{work}']").click

        expect(page).to have_text case_insensitive_string(work)

        visit "/"
      end
    end
  end

  def case_insensitive_string(string)
    %r{#{string.humanize}}i
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
