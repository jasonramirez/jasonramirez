require "rails_helper"

RSpec.describe Post, type: :model do
  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:body) }
    it { should validate_presence_of(:summary) }
    it { should validate_presence_of(:published_date) }
  end

  describe "associations" do
    it { should have_many(:post_hashtags).dependent(:destroy) }
    it { should have_many(:hashtags).through(:post_hashtags) }
  end

  describe "scopes" do
    let!(:published_post) { create(:post, published: true, published_date: 1.day.ago) }
    let!(:draft_post) { create(:post, published: false, published_date: 1.day.ago) }
    let!(:future_post) { create(:post, published: true, published_date: 1.day.from_now) }

    describe ".published" do
      it "returns only published posts" do
        expect(Post.published).to include(published_post)
        expect(Post.published).to_not include(draft_post)
      end
    end

    describe ".ordered_by_published_date" do
      it "orders posts by published date descending" do
        expect(Post.ordered_by_published_date.first).to eq(future_post)
        expect(Post.ordered_by_published_date.last).to eq(published_post)
      end
    end
  end

  describe "methods" do
    let(:post) { create(:post, title: "Test Post", published_date: Date.new(2023, 6, 15)) }

    describe "#pretty_published_date" do
      it "formats the published date nicely" do
        expect(post.pretty_published_date).to eq("June 15, 2023")
      end
    end

    describe "#published_state_class" do
      context "when published" do
        let(:post) { create(:post, published: true) }
        
        it "returns published class" do
          expect(post.published_state_class).to eq("published")
        end
      end

      context "when draft" do
        let(:post) { create(:post, published: false) }
        
        it "returns draft class" do
          expect(post.published_state_class).to eq("draft")
        end
      end
    end

    describe "#slug" do
      it "generates a URL-friendly slug from title" do
        expect(post.slug).to eq("test-post")
      end
    end
  end

  describe "search functionality" do
    let!(:post1) { create(:post, title: "Ruby on Rails Guide", body: "Learn Ruby on Rails") }
    let!(:post2) { create(:post, title: "JavaScript Basics", body: "JavaScript fundamentals") }
    let!(:post3) { create(:post, title: "CSS Styling", body: "CSS and design") }

    describe ".search_by_title" do
      it "finds posts by title" do
        results = Post.search_by_title("Ruby")
        expect(results).to include(post1)
        expect(results).to_not include(post2, post3)
      end
    end

    describe ".search_by_body" do
      it "finds posts by body content" do
        results = Post.search_by_body("JavaScript")
        expect(results).to include(post2)
        expect(results).to_not include(post1, post3)
      end
    end
  end
end
