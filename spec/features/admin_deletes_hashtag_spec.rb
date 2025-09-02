require "rails_helper"

RSpec.feature "Admin deletes hashtag", js: true do
  context "from the hashtags list" do
    it "removes the hashtag" do
      sign_in_admin
      hashtag_one = create(:hashtag, label: "hashtagone")
      hashtag_two = create(:hashtag, label: "hashtagtwo")

      visit admins_hashtags_path
      first(".admin-post-item__actions a").click

      expect(page).to_not have_text hashtag_one.label
      expect(page).to have_text hashtag_two.label
    end
  end

  def sign_in_admin
    admin = create(:admin)
    login_as admin, scope: :admin
  end
end
