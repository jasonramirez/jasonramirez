require "rails_helper"

feature "Guest searches posts" do
  context "doesn't add search parameters" do
    it "doesn't add search paramet" do
      create(:post, title: "Super duper post")

      visit posts_path
      fill_in "search", with: " "
      find("#search_posts_submit", visible: false).click

      expect(page).not_to have_css("#search_results")
    end
  end

  context "adds search parameters" do
    it "shows a list of searched posts" do
      create(:post, title: "Super duper post")

      visit posts_path
      fill_in "search", with: "Super"
      find("#search_posts_submit", visible: false).click

      expect(search_results).to have_text "Super duper post"
    end
  end

  private

  def search_results
    page.find("#search_results")
  end
end
