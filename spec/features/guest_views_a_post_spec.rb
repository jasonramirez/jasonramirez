require "rails_helper"

RSpec.feature "Guest views posts" do
  scenario "published" do
    post_one = create(:post, title: "Post One", published: true)

    visit post_path(post_one)

    expect(page).to have_text(post_one.title)
  end

  scenario "not published" do
    post_one = create(:post, title: "Post One", published: false)

    visit post_path(post_one)

    expect(page).to have_text(t("posts.show.removed"))
  end
end
