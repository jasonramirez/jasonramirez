require "rails_helper"

RSpec.describe Admins::PostsController, type: :controller do
  let(:admin) { create(:admin) }
  let(:blog_post) { create(:post) }

  before do
    sign_in admin, scope: :admin
  end

  describe "permitted parameters" do
    let(:all_params) do
      {
        post_markdown: "# Test markdown content",
        summary: "Test summary",
        tldr_transcript: "Test TLDR",
        published: true,
        published_date: 1.day.ago,
        title: "Test Title",
        video_src: "https://example.com/video.mp4",
        hashtag_ids: [1, 2, 3],
        # These should be filtered out
        id: 999,
        created_at: 1.day.ago,
        updated_at: 1.hour.ago,
        slug: "should-not-be-settable",
        post_text: "Should be auto-generated"
      }
    end

    describe "POST #create" do
      it "permits the correct parameters" do
        # Test that post_params method permits the expected parameters
        controller_instance = described_class.new
        controller_instance.params = ActionController::Parameters.new(post: all_params)
        
        permitted_params = controller_instance.send(:post_params)
        
        # Should permit these parameters
        expect(permitted_params.keys).to include(
          "post_markdown", "summary", "tldr_transcript", 
          "published", "published_date", "title", "video_src"
        )
        
        # Should not permit these
        expect(permitted_params.keys).not_to include("id", "created_at", "post_text")
      end

      it "filters out unpermitted parameters" do
        request.env["HTTP_ACCEPT"] = "text/vnd.turbo-stream.html"
        post :create, params: { post: all_params }
        
        created_post = Post.last
        
        # These should not be settable via params
        expect(created_post.id).not_to eq(999)
        expect(created_post.slug).not_to eq("should-not-be-settable")
      end
    end

    describe "PATCH #update" do
      it "permits the correct parameters for update" do
        expect(controller).to receive(:post_params).and_call_original
        
        request.env["HTTP_ACCEPT"] = "text/vnd.turbo-stream.html"
        patch :update, params: { id: blog_post.to_param, post: all_params }
        
        blog_post.reload
        
        # Should permit these
        expect(blog_post.post_markdown).to eq("# Test markdown content")
        expect(post.summary).to eq("Test summary")
        expect(post.tldr_transcript).to eq("Test TLDR")
        expect(post.published).to be true
        expect(post.title).to eq("Test Title")
        expect(post.video_src).to eq("https://example.com/video.mp4")
        
        # Should auto-generate post_text from post_markdown
        expect(post.post_text).to include("Test markdown content")
      end

      it "specifically permits post_markdown (not the old body parameter)" do
        # This test ensures we're using the new column name
        request.env["HTTP_ACCEPT"] = "text/vnd.turbo-stream.html"
        patch :update, params: { 
          id: blog_post.to_param, 
          post: { post_markdown: "# New markdown content" }
        }
        
        blog_post.reload
        expect(blog_post.post_markdown).to eq("# New markdown content")
      end

      it "does not permit old body parameter" do
        # This test ensures the old column name is not accidentally permitted
        original_markdown = blog_post.post_markdown
        
        request.env["HTTP_ACCEPT"] = "text/vnd.turbo-stream.html"
        patch :update, params: { 
          id: blog_post.to_param, 
          post: { body: "This should not work" }
        }
        
        blog_post.reload
        expect(blog_post.post_markdown).to eq(original_markdown)
        expect(blog_post.post_markdown).not_to eq("This should not work")
      end
    end

    describe "hashtag_ids parameter" do
      let!(:hashtag1) { create(:hashtag) }
      let!(:hashtag2) { create(:hashtag) }

      it "permits hashtag_ids array" do
        request.env["HTTP_ACCEPT"] = "text/vnd.turbo-stream.html"
        patch :update, params: { 
          id: blog_post.to_param, 
          post: { hashtag_ids: [hashtag1.id, hashtag2.id] }
        }
        
        blog_post.reload
        expect(blog_post.hashtag_ids).to contain_exactly(hashtag1.id, hashtag2.id)
      end
    end
  end

  describe "strong parameters validation" do
    it "raises error when post parameter is missing" do
      expect {
        patch :update, params: { id: post.to_param }, format: :turbo_stream
      }.to raise_error(ActionController::ParameterMissing)
    end
  end
end
