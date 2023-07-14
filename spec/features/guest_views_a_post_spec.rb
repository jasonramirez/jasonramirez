require "rails_helper"

RSpec.feature "Guest views posts" do
  scenario "published" do
    post_one = create(:post, title: "Post One", published: true)
    create(:post, title: "Post Two", published: true)

    visit post_path(post_one)

    expect(page).to have_text(post_one.title)
  end

  scenario "not published" do
    post_one = create(:post, title: "Post One", published: false)
    create(:post, title: "Post Two", published: true)

    visit post_path(post_one)

    expect(page).to_not have_text("Post One")
  end
end
