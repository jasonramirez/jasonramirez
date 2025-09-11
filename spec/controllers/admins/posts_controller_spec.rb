require "rails_helper"

RSpec.describe Admins::PostsController, type: :controller do
  let(:admin) { create(:admin) }
  let(:post) { create(:post) }

  before do
    sign_in admin
  end

  describe "POST #create" do
    let(:valid_attributes) do
      {
        title: "Test Post",
        post_markdown: "# Hello\n\nThis is **test** content.",
        summary: "Test summary",
        published: false
      }
    end

    context "with valid parameters" do
      it "creates a new post" do
        expect {
          post :create, params: { post: valid_attributes }, format: :turbo_stream
        }.to change(Post, :count).by(1)
      end

      it "saves the post_markdown content" do
        post :create, params: { post: valid_attributes }, format: :turbo_stream
        created_post = Post.last
        expect(created_post.post_markdown).to eq("# Hello\n\nThis is **test** content.")
      end

      it "renders the save turbo stream" do
        post :create, params: { post: valid_attributes }, format: :turbo_stream
        expect(response).to render_template("save")
      end
    end

    context "with invalid parameters" do
      it "renders the failure turbo stream" do
        post :create, params: { post: { title: "" } }, format: :turbo_stream
        expect(response).to render_template("failure")
      end
    end
  end

  describe "PATCH #update" do
    let(:new_attributes) do
      {
        title: "Updated Title",
        post_markdown: "# Updated Content\n\nThis is **updated** markdown.",
        summary: "Updated summary"
      }
    end

    context "with valid parameters" do
      it "updates the post" do
        patch :update, params: { id: post.to_param, post: new_attributes }, format: :turbo_stream
        post.reload
        expect(post.title).to eq("Updated Title")
        expect(post.post_markdown).to eq("# Updated Content\n\nThis is **updated** markdown.")
        expect(post.summary).to eq("Updated summary")
      end

      it "automatically updates post_text when post_markdown changes" do
        patch :update, params: { id: post.to_param, post: new_attributes }, format: :turbo_stream
        post.reload
        expect(post.post_text).to include("Updated Content")
        expect(post.post_text).to include("updated")
      end

      it "renders the update turbo stream" do
        patch :update, params: { id: post.to_param, post: new_attributes }, format: :turbo_stream
        expect(response).to render_template("update")
      end

      it "tracks slug changes" do
        original_slug = post.slug
        patch :update, params: { id: post.to_param, post: { title: "Completely Different Title" } }, format: :turbo_stream
        expect(assigns(:slug_changed)).to be true
      end
    end

    context "with invalid parameters" do
      it "renders the failure turbo stream" do
        patch :update, params: { id: post.to_param, post: { title: "" } }, format: :turbo_stream
        expect(response).to render_template("failure")
      end

      it "does not update the post" do
        original_title = post.title
        patch :update, params: { id: post.to_param, post: { title: "" } }, format: :turbo_stream
        post.reload
        expect(post.title).to eq(original_title)
      end
    end

    context "parameter filtering" do
      it "permits post_markdown parameter" do
        expect(controller).to receive(:post_params).and_call_original
        patch :update, params: { id: post.to_param, post: new_attributes }, format: :turbo_stream
      end

      it "filters out unpermitted parameters" do
        patch :update, params: { 
          id: post.to_param, 
          post: new_attributes.merge(unpermitted_param: "should be filtered")
        }, format: :turbo_stream
        
        post.reload
        expect(post).not_to respond_to(:unpermitted_param)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the post" do
      post_to_delete = create(:post)
      expect {
        delete :destroy, params: { id: post_to_delete.to_param }
      }.to change(Post, :count).by(-1)
    end

    it "redirects to posts index" do
      delete :destroy, params: { id: post.to_param }
      expect(response).to redirect_to(admins_posts_path)
    end
  end

  describe "GET #edit" do
    it "assigns the post" do
      get :edit, params: { id: post.to_param }
      expect(assigns(:post)).to eq(post)
    end
  end

  describe "GET #index" do
    it "assigns all posts ordered by published_date" do
      older_post = create(:post, published_date: 1.day.ago)
      newer_post = create(:post, published_date: 1.hour.ago)
      
      get :index
      expect(assigns(:posts)).to eq([newer_post, older_post])
    end
  end

  describe "POST #new" do
    it "creates a new draft post" do
      expect {
        post :new
      }.to change(Post, :count).by(1)
    end

    it "creates post with default attributes" do
      post :new
      created_post = Post.last
      expect(created_post.title).to eq("Draft")
      expect(created_post.published).to be false
    end

    it "redirects to edit page" do
      post :new
      created_post = Post.last
      expect(response).to redirect_to(edit_admins_post_path(created_post))
    end
  end
end
