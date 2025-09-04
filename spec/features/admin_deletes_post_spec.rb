require "rails_helper"

RSpec.feature "Admin deletes post", js: true do
  context "from the posts list" do
    it "removes the post" do
      sign_in_admin
      post_one = create(:post, title: "This is the post title")
      post_two = create(:post, title: "This is post 2")

      visit admins_posts_path
      within first(".admin-post-item") do
        accept_confirm do
          find("a[data-turbo-method='delete']").click
        end
      end

      expect(page).to_not have_text post_one.title
      expect(page).to have_text post_two.title
    end
  end

  def sign_in_admin
    admin = create(:admin)
    login_as admin, scope: :admin
  end
end
