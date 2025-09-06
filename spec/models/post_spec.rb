require "rails_helper"

RSpec.describe Post, type: :model do
  describe "validations" do
    it { should validate_presence_of(:title) }
  end

  describe "associations" do
    it { should have_and_belong_to_many(:hashtags) }
  end

  describe "methods" do
    let(:post) { create(:post, title: "Test Post", published_date: Date.new(2023, 6, 15)) }

    describe "#pretty_published_date" do
      it "formats the published date as m/d/yy" do
        expect(post.pretty_published_date).to eq("6/15/23")
      end
    end

    describe "#published_state_class" do
      context "when published" do
        let(:post) { create(:post, published: true) }
        
        it "returns the published boolean value" do
          expect(post.published_state_class).to eq(true)
        end
      end

      context "when not published" do
        let(:post) { create(:post, published: false) }
        
        it "returns 'not-published'" do
          expect(post.published_state_class).to eq("not-published")
        end
      end
    end

    describe "#published_state" do
      context "when published" do
        let(:post) { create(:post, published: true) }
        
        it "returns 'Published'" do
          expect(post.published_state).to eq("Published")
        end
      end

      context "when not published" do
        let(:post) { create(:post, published: false) }
        
        it "returns 'Not Published'" do
          expect(post.published_state).to eq("Not Published")
        end
      end
    end

    describe "#slug" do
      it "generates a URL-friendly slug from title" do
        expect(post.slug).to eq("test-post")
      end
    end

    describe "#parsed_body" do
      let(:post) { create(:post, post_markdown: "# Hello\n\nThis is **bold** text.") }
      
      it "converts markdown to HTML" do
        expect(post.parsed_body).to include("<h1>")
        expect(post.parsed_body).to include("<strong>")
      end
    end
  end
end
