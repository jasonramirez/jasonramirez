require "rails_helper"

feature "Guest views protected case studies" do
  context "from the index page" do
    it "has a link to each case study" do
      visit root_path

      within ".site-header" do
        click_link t("navigation.works")
      end

      works.each do |work|
        expect(page).to have_css(
          "a[href='protected_works/#{work[0][:path]}']"
        )
      end
    end
  end

  context "without a password" do
    it "and isn't allowed to view it" do
      visit works_path

      click_on works.first[0][:title]

      expect(page).to have_text t("lockup.lockup.unlock.heading")
    end
  end

  context "with a password" do
    it "and is allowed to view it" do
      visit works_path

      click_on works.first[0][:title]

      fill_in "lockup_codeword", with: ENV['LOCKUP_CODEWORD']
      click_button t("lockup.lockup.unlock.submit")

      expect(page).to have_text works.first[0][:title]
    end
  end

  private

  def works
    [
      [
        :title => "Smartifying Activation",
        :path => "dropbox_smartifying_activation"
      ],
      [
        :title => "Enhancing Collaboration",
        :path => "dropbox_enhancing_collaboration"],
    ]
  end
end
