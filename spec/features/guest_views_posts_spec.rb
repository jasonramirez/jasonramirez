require "rails_helper"

RSpec.feature "Guest views posts" do
  scenario "not published" do
    post_one = create(:post, title: "Post One", published: false)

    visit posts_path

    expect(page).to_not have_text post_one.title
  end

  scenario "as a list" do
    post_one = create(:post, title: "Post One", summary: "")
    post_two = create(:post, title: "Post Two", summary: " ")

    visit posts_path

    expect(page).to have_text post_one.title
    expect(page).to have_text post_two.title
  end

  scenario "has a slugged url" do
    post = create(:post, title: "Slugged Title")
    expected_path = "/posts/slugged-title"

    visit posts_path
    click_link "Slugged Title"

    expect(page).to have_text post.title
    expect(current_path).to have_content(expected_path)
  end
end
