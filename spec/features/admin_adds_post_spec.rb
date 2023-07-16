require "rails_helper"

feature "Admin adds post" do
  context "by clicking the add new posts button on the all posts page" do
    it "successfully creates the post and shows a success flash." do
      sign_in_admin
      visit admins_posts_path

      page.find("#new_post_link").click
      fill_new_post_form

      expect(page).to have_text t("admins.flash.created")
    end
  end

  context "by clicking the add new posts button on the all posts page" do
    it "shows the id and link of the post" do
      sign_in_admin
      visit admins_posts_path

      page.find("#new_post_link").click
      fill_new_post_form

      expect(page).to have_text Post.all.first.id
      expect(page).to have_text post_url(Post.all.first)
    end
  end

  context "from the new posts page scucessfully" do
    it "shows a success message" do
      sign_in_admin
      visit new_admins_post_path

      fill_new_post_form

      expect(page).to have_text t("admins.flash.created")
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


  context "then previews it" do
    it "shows the post" do
      create(:post, title: "Post One", published: true)

      sign_in_admin
      visit admins_posts_path
      click_link "Post One"
      click_link "Preview"

      expect(page).to have_text  "Post One"
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
