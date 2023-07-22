require "rails_helper"

feature "Admin edits post", js: true do
  context "from the post's page" do
    it "successfully updates the post and shows a success flash." do
      post = create(:post)
      sign_in_admin

      visit edit_admins_post_path(post)

      fill_form(:post, title: "New Title")

      page.find("#save_post").click

      expect(page).to have_text t("admins.flash.created")
      visit admins_posts_path

      expect(page).to have_text "New Title"
    end
  end

  private

  def sign_in_admin
    admin = create(:admin)
    login_as admin, scope: :admin
  end
end
