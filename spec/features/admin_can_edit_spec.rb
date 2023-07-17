require "rails_helper"

feature "Admin can edit" do
  context "when logged in, and by clicking the admin button" do
    it "takes them to the admin posts index page." do
      sign_in_admin

      visit root_path

      page.find("#admin_edit_link").click

      expect(page).to have_text t("admins.posts.index.all_posts")
    end
  end

  context "post from the post itself when logged in" do
    it "takes them directly to the post." do
      sign_in_admin
      post = create(:post, title: "Post One", published: true)

      visit post_path(post)

      page.find("#post_edit_link").click

      expect(page).to have_text "ID: #{post.id}"
    end
  end

  private

  def sign_in_admin
    admin = create(:admin)
    login_as admin, scope: :admin
  end
end
