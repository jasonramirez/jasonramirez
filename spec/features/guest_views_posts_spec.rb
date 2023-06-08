require "rails_helper"

RSpec.feature "Guest views posts" do
  scenario "not published" do
    post_one = create(:post, title: "Post One", published: false)

    visit posts_path

    expect(page).to_not have_text post_one.title
  end

  scenario "as a list" do
    post_one = create(:post, title: "Post One", long_title: "")
    post_two = create(:post, title: "Post Two", long_title: " ")

    visit posts_path

    expect(page).to have_text post_one.title
    expect(page).to have_text post_two.title
  end

  scenario "with a long title" do
    post_one = create(:post, title: "Short Title", long_title: "Long Title")

    visit posts_path

    expect(page).to have_text post_one.long_title
    expect(page).to_not have_text post_one.title
  end

  scenario "has a slugged url" do
    post_one = create(:post, title: "Short Title", long_title: "Long Title")
    expected_path = "/posts/short-title"

    visit posts_path
    click_link "Long Title"

    expect(page).to have_text post_one.title
    expect(current_path).to have_content(expected_path)
  end
end
