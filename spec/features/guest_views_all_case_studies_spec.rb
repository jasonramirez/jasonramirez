require "rails_helper"

RSpec.feature "Guest views all case studies" do
  context "on the index page" do
    it "has thumbnail links to each case study" do
      visit "/"

      case_studies.each do |case_study|
        expect(page).to have_css "a[href='case_studies/#{case_study}']"

        page.find(:xpath, ".//a[@href='case_studies/#{case_study}']").click

        expect(page).to have_text case_insensitive_string(case_study)

        visit "/"
      end
    end
  end

  def case_insensitive_string(string)
    %r{#{string.humanize}}i
  end

  def case_studies
    [
      "penner",
      "piggy",
      "tinysplash",
    ]
  end
end
