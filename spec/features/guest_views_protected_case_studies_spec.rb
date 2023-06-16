require "rails_helper"

feature "Guest views protected case studies" do
  context "from the index page" do
    it "has a link to each case study" do
      visit root_path

      within ".site-header" do
        click_link t("navigation.case_studies")
      end

      case_studies.each do |case_study|
        expect(page).to have_css(
          "a[href='protected_case_studies/#{case_study[0][:path]}']"
        )

        visit "/case_studies"
      end
    end
  end

  context "without a password" do
    it "and isn't allowed to view it" do
      visit case_studies_path

      click_on case_studies.first[0][:title]

      expect(page).to have_text t("lockup.lockup.unlock.heading")
    end
  end

  context "with a password" do
    it "and is allowed to view it" do
      visit case_studies_path

      click_on case_studies.first[0][:title]

      fill_in "lockup_codeword", with: ENV['LOCKUP_CODEWORD']
      click_button t("lockup.lockup.unlock.submit")

      expect(page).to have_text case_studies.first[0][:title]
    end
  end

  def case_studies
    [
      [:title => "Mayo Clinic", :path => "mayo_clinic"],
      [:title => "Dropbox Activation", :path => "dropbox_activation"],
    ]
  end
end
