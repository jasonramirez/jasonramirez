require "rails_helper"

RSpec.describe "Posts", type: :request do
  let!(:published_post) { create(:post, title: "Published Post", published: true, published_date: 1.day.ago) }
  let!(:unpublished_post) { create(:post, title: "Draft Post", published: false) }

  describe "GET /posts" do
    it "returns a successful response" do
      get posts_path
      expect(response).to be_successful
    end

    it "shows published posts" do
      get posts_path
      expect(response.body).to include("Published Post")
    end

    it "does not show unpublished posts" do
      get posts_path
      expect(response.body).not_to include("Draft Post")
    end

    it "returns correct content type" do
      get posts_path
      expect(response.content_type).to include("text/html")
    end
  end

  describe "GET /posts/:id" do
    context "when post is published" do
      it "returns a successful response" do
        get post_path(published_post)
        expect(response).to be_successful
      end

      it "shows the post content" do
        get post_path(published_post)
        expect(response.body).to include(published_post.title)
      end
    end

    context "when post is not published" do
      it "still returns a successful response" do
        get post_path(unpublished_post)
        expect(response).to be_successful
      end

      it "shows the unpublished post content" do
        get post_path(unpublished_post)
        expect(response.body).to include(unpublished_post.title)
      end
    end

  end

  describe "GET /posts with search" do
    let!(:searchable_post) { create(:post, title: "Searchable Content", published: true) }

    it "returns results for valid search" do
      get posts_path, params: { search: "Searchable" }
      expect(response).to be_successful
      expect(response.body).to include("Searchable Content")
    end

    it "handles empty search gracefully" do
      get posts_path, params: { search: "" }
      expect(response).to be_successful
    end
  end

  describe "GET /posts with Turbo Stream format" do
    let!(:searchable_post) { create(:post, title: "Searchable Content", published: true) }

    it "returns turbo stream for search requests" do
      get posts_path, params: { search: "Searchable" }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to be_successful
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
      expect(response.body).to include("turbo-stream")
    end

    it "returns turbo stream for clear requests" do
      get posts_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to be_successful
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
      expect(response.body).to include("turbo-stream")
    end

    it "includes search-results and posts-results targets" do
      get posts_path, params: { search: "Searchable" }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response.body).to include('target="search-results"')
      expect(response.body).to include('target="posts-results"')
    end
  end
end
