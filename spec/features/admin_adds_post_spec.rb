require "rails_helper"

RSpec.feature "Admin adds post" do
  context "from the navigation" do
    it "shows a list of all posts" do
      sign_in_admin
      visit admin_posts_path

      click_on t("admin.navigation.new_post")
      fill_new_post_form

      expect(page).to have_text I18n.t("admin.flash.created")
    end
  end

  context "from the new posts page scucessfully" do
    it "shows a success message" do
      sign_in_admin
      visit new_admin_post_path

      fill_new_post_form

      expect(page).to have_text I18n.t("admin.flash.created")
    end
  end

  context "from the new posts page not successfully" do
    it "shows a failure message" do
      sign_in_admin
      visit new_admin_post_path

      fill_form_and_submit(:post, :new, {})

      expect(page).to have_text I18n.t("admin.flash.failed")
    end
  end

  def fill_new_post_form
    fill_form_and_submit(
      :post,
      title: "Title",
      body: "This is the body.",
      published: true,
    )
  end

  def sign_in_admin
    admin = create(:admin)
    login_as admin, scope: :admin
  end
end
