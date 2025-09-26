require "rails_helper"

feature "Guest searches posts" do
  before(:each) do
    Post.destroy_all
    Hashtag.destroy_all
    Admin.destroy_all
  end

  it "shows posts that match the search term" do
    post1 = create(:post, title: "Rails Tutorial", published: true)
    post2 = create(:post, title: "JavaScript Guide", published: true)

    visit posts_path
    
    # Search for Rails
    fill_in "search", with: "Rails"
    find("button[type='submit']").click

    # Should show Rails post, not JavaScript post
    expect(page).to have_text "Rails Tutorial"
    expect(page).not_to have_text "JavaScript Guide"
  end

  it "shows all posts when search is cleared" do
    post1 = create(:post, title: "Post One", published: true)
    post2 = create(:post, title: "Post Two", published: true)

    visit posts_path
    
    # Search for One
    fill_in "search", with: "One"
    find("button[type='submit']").click
    
    expect(page).to have_text "Post One"
    expect(page).not_to have_text "Post Two"
    
    # Clear search
    find("button[data-search-form-target='clearButton']").click
    
    # Should show both posts
    expect(page).to have_text "Post One"
    expect(page).to have_text "Post Two"
  end
end