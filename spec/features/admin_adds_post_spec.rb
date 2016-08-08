require "rails_helper"

RSpec.feature "Admin adds post" do
  context "from the navigation" do
    it "shows a list of all posts" do
      sign_in_admin
      visit admins_posts_path

      click_on t("admins.navigation.new_post")
      fill_new_post_form

      expect(page).to have_text t("admins.flash.created")
    end
  end

  context "from the new posts page scucessfully" do
    it "shows a success message" do
      sign_in_admin
      visit new_admins_post_path

      fill_new_post_form

      expect(page).to have_text I18n.t("admins.flash.created")
    end
  end

  context "from the new posts page not successfully" do
    it "shows a failure message" do
      sign_in_admin
      visit new_admins_post_path

      fill_form(:post, :new, title: "")
      click_button t("admins.posts.form.save")

      expect(page).to have_text t("admins.flash.failed")
    end
  end

  def fill_new_post_form
    fill_form(
      :post,
      title: "Title",
      body: "This is the body.",
      published: true,
    )
    click_button t("admins.posts.form.save")
  end

  def sign_in_admin
    admin = create(:admin)
    login_as admin, scope: :admin
  end
end
