require "rails_helper"

RSpec.describe Admins::PostsController, type: :controller do
  let(:admin) { create(:admin) }
  let(:post) { create(:post) }

  before do
    sign_in admin
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
        expect(controller).to receive(:post_params).and_call_original
        
        post :create, params: { post: all_params }, format: :turbo_stream
        
        created_post = Post.last
        
        # Should permit these
        expect(created_post.post_markdown).to eq("# Test markdown content")
        expect(created_post.summary).to eq("Test summary")
        expect(created_post.tldr_transcript).to eq("Test TLDR")
        expect(created_post.published).to be true
        expect(created_post.title).to eq("Test Title")
        expect(created_post.video_src).to eq("https://example.com/video.mp4")
        
        # Should auto-generate post_text from post_markdown, not use provided value
        expect(created_post.post_text).to include("Test markdown content")
        expect(created_post.post_text).not_to eq("Should be auto-generated")
      end

      it "filters out unpermitted parameters" do
        post :create, params: { post: all_params }, format: :turbo_stream
        
        created_post = Post.last
        
        # These should not be settable via params
        expect(created_post.id).not_to eq(999)
        expect(created_post.slug).not_to eq("should-not-be-settable")
      end
    end

    describe "PATCH #update" do
      it "permits the correct parameters for update" do
        expect(controller).to receive(:post_params).and_call_original
        
        patch :update, params: { id: post.to_param, post: all_params }, format: :turbo_stream
        
        post.reload
        
        # Should permit these
        expect(post.post_markdown).to eq("# Test markdown content")
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
        patch :update, params: { 
          id: post.to_param, 
          post: { post_markdown: "# New markdown content" }
        }, format: :turbo_stream
        
        post.reload
        expect(post.post_markdown).to eq("# New markdown content")
      end

      it "does not permit old body parameter" do
        # This test ensures the old column name is not accidentally permitted
        original_markdown = post.post_markdown
        
        patch :update, params: { 
          id: post.to_param, 
          post: { body: "This should not work" }
        }, format: :turbo_stream
        
        post.reload
        expect(post.post_markdown).to eq(original_markdown)
        expect(post.post_markdown).not_to eq("This should not work")
      end
    end

    describe "hashtag_ids parameter" do
      let!(:hashtag1) { create(:hashtag) }
      let!(:hashtag2) { create(:hashtag) }

      it "permits hashtag_ids array" do
        patch :update, params: { 
          id: post.to_param, 
          post: { hashtag_ids: [hashtag1.id, hashtag2.id] }
        }, format: :turbo_stream
        
        post.reload
        expect(post.hashtag_ids).to contain_exactly(hashtag1.id, hashtag2.id)
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
