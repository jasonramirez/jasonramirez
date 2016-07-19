require "rails_helper"

RSpec.feature "Admin adds post" do
  context "from the post" do
    it "shows a success message" do
      post = create(:post, published: true)
      visit edit_admin_post_path(post)

      fill_form_and_submit(:post, :edit, title: "New Title")

      expect(page).to have_selector("input[value='New Title']")
      expect(page).to have_text t("admin.flash.updated")
    end
  end
end
