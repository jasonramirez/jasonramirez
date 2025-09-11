require "rails_helper"

feature "Guest views protected case studies" do
  context "from the index page" do
    it "has a link to each case study" do
      visit root_path

      within ".navigation-primary" do
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

      click_on "Smartifying Activation"

      expect(page).to have_text t("password_protection.unlock.heading")
    end
  end

  context "with a password" do
    it "and is allowed to view it" do
      visit works_path

      click_on "Smartifying Activation"

      # Check if we're on the password protection page
      expect(page).to have_text t("password_protection.unlock.heading")
      
      # Check if the form is present
      expect(page).to have_css("form")
      expect(page).to have_field("password_protection_codeword")

      fill_in "password_protection_codeword", with: ENV['LOCKUP_CODEWORD']
      click_button t("password_protection.unlock.submit")

      expect(page).to have_text "Smartifying Activation"
    end
  end

  private

  def works
    [
      [
        :title => "Smartifying Activation, 2023",
        :path => "dropbox_smartifying_activation"
      ],
      [
        :title => "Enhancing Collaboration, 2022",
        :path => "dropbox_enhancing_collaboration"
      ],
    ]
  end
end
