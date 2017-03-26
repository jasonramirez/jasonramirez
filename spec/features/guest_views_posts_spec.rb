require "rails_helper"

RSpec.feature "Guest views posts" do
  scenario "not published" do
    post_one = create(:post, title: "Post One", published: false)

    visit posts_path

    expect(page).to_not have_text post_one.title
  end

  scenario "as a list" do
    post_one = create(:post, title: "Post One")
    post_two = create(:post, title: "Post One")

    visit posts_path

    expect(page).to have_text post_one.title
    expect(page).to have_text post_two.title
  end

  scenario "with a long title" do
    post_one = create(:post, title: "ShortTitle", long_title: "LongerTitle")

    visit posts_path

    expect(page).to have_text post_one.long_title
    expect(page).to_not have_text post_one.title
  end
end
