require "rails_helper"

feature "Guest searches posts" do
  before(:each) do
    # Ensure clean state before each test
    Post.destroy_all
    Hashtag.destroy_all
    Admin.destroy_all
  end

  context "doesn't add search parameters" do
    it "doesn't add search paramet" do
      post = create(:post)

      visit posts_path
      fill_in "search", with: " "
      within "#search_form" do
        find("button[type='submit']").click
      end

      within "#search-results" do
        expect(page).not_to have_text post.title
      end
    end
  end

  context "with basic text" do
    it "shows a list of results that match" do
      post = create(:post)

      visit posts_path
      fill_in "search", with: post.title
      within "#search_form" do
        find("button[type='submit']").click
      end

      within ".post-search__results" do
        expect(page).to have_text post.title
      end
    end
  end

  context "with a hashtag" do
    it "shows a list of restults that match" do
      hashtag = create(:hashtag, label: "design")
      create(:post_with_hashtag, title: "Post", hashtags: [hashtag])

      visit posts_path
      fill_in "search", with: "design"
      within "#search_form" do
        find("button[type='submit']").click
      end

      expect(page).to have_text "Post"
    end
  end

  context "clear button functionality" do
    it "shows clear button when there is search text" do
      visit posts_path
      fill_in "search", with: "test"
      
      expect(page).to have_css("button[data-search-form-target='clearButton']", visible: true)
    end

    it "hides clear button when search is empty" do
      visit posts_path
      
      expect(page).to have_css("button[data-search-form-target='clearButton']", visible: false)
    end

    it "clears search and shows all posts when clear button is clicked" do
      post1 = create(:post, title: "Post One", published: true)
      post2 = create(:post, title: "Post Two", published: true)
      
      visit posts_path
      fill_in "search", with: "One"
      within "#search_form" do
        find("button[type='submit']").click
      end
      
      expect(page).to have_text "Post One"
      expect(page).not_to have_text "Post Two"
      
      # Click clear button
      find("button[data-search-form-target='clearButton']").click
      
      expect(page).to have_text "Post One"
      expect(page).to have_text "Post Two"
      expect(find("input[name='search']").value).to be_empty
    end
  end

  context "edge cases" do
    it "handles search with special characters" do
      post = create(:post, title: "Post with @#$%^&*()", published: true)
      
      visit posts_path
      fill_in "search", with: "@#$%"
      within "#search_form" do
        find("button[type='submit']").click
      end
      
      expect(page).to have_text "Post With @#$%^&*()"
    end

    it "handles very long search terms" do
      long_search = "a" * 1000
      post = create(:post, title: "Short", published: true)
      
      visit posts_path
      fill_in "search", with: long_search
      within "#search_form" do
        find("button[type='submit']").click
      end
      
      # Should not crash and should show no results
      expect(page).to have_text "0 posts found"
    end

    it "handles search with only whitespace" do
      post = create(:post, title: "Test Post", published: true)
      
      visit posts_path
      fill_in "search", with: "   "
      within "#search_form" do
        find("button[type='submit']").click
      end
      
      # Should show all posts (same as empty search)
      expect(page).to have_text "Test Post"
    end
  end
end
