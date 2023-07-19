require "rails_helper"

feature "Guest searches posts" do
  context "doesn't add search parameters" do
    it "doesn't add search paramet" do
      post = create(:post)

      visit posts_path
      fill_in "search", with: " "
      within "#search_form" do
        find("#search_posts_submit", visible: false).click
      end

      within ".post-search__results" do
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
        find("#search_posts_submit", visible: false).click
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
        find("#search_posts_submit", visible: false).click
      end

      expect(page).to have_text "Post"
    end
  end
end
