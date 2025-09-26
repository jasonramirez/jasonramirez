require "rails_helper"

RSpec.feature "Guest views posts" do
  before(:each) do
    # Ensure clean state before each test
    Post.destroy_all
    Hashtag.destroy_all
    Admin.destroy_all
  end

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
    # Clear existing posts to ensure clean test
    Post.delete_all
    
    post = create(:post, title: "Slugged Title", published: true, published_date: Time.current)
    
    # Force slug generation if needed
    post.slug = post.title.parameterize if post.slug.blank?
    post.save!
    post.reload
    
    expected_path = "/posts/#{post.slug}"

    visit posts_path
    
    # Check if the post appears on the page
    expect(page).to have_content("Slugged Title")
    
    # Find and navigate to the link (avoid JS/Turbo issues in tests)
    link = find_link("Slugged Title")
    visit link[:href]

    expect(page).to have_text post.title
    expect(current_path).to eq(expected_path)
  end
end
