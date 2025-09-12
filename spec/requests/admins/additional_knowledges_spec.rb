require 'rails_helper'

RSpec.describe "Admins::AdditionalKnowledges", type: :request do
  let(:admin) { create(:admin) }
  let(:additional_knowledge) { create(:additional_knowledge) }

  before do
    sign_in_admin(admin)
  end

  describe "GET /index" do
    it "returns http success" do
      get admins_additional_knowledges_path
      expect(response).to have_http_status(:success)
    end

    it "assigns @additional_knowledges" do
      additional_knowledge
      get admins_additional_knowledges_path
      expect(assigns(:additional_knowledges)).to include(additional_knowledge)
    end

    it "assigns knowledge base statistics" do
      # Create test data
      create(:knowledge_item, category: 'Blog Post')
      create(:knowledge_item, category: 'Case Study')
      create(:additional_knowledge)
      create(:knowledge_chunk)

      get admins_additional_knowledges_path
      
      # Check that the counts match what we expect
      expect(assigns(:posts_count)).to eq(KnowledgeItem.where(category: 'Blog Post').count)
      expect(assigns(:case_studies_count)).to eq(KnowledgeItem.where(category: 'Case Study').count)
      expect(assigns(:additional_knowledge_count)).to eq(AdditionalKnowledge.count)
      expect(assigns(:total_knowledge_items)).to eq(assigns(:posts_count) + assigns(:case_studies_count) + assigns(:additional_knowledge_count))
      expect(assigns(:total_chunks)).to eq(KnowledgeChunk.count)
    end

    it "assigns pending posts" do
      published_post = create(:post, published: true)
      create(:knowledge_item, category: 'Blog Post', source: "post_#{published_post.id}")

      get admins_additional_knowledges_path
      
      expect(assigns(:pending_posts)).to be_empty
      expect(assigns(:pending_posts_count)).to eq(0)
    end

    it "assigns case study information" do
      create(:knowledge_item, category: 'Case Study', title: 'Test Case Study')
      
      get admins_additional_knowledges_path
      
      expect(assigns(:knowledge_base_case_studies_count)).to eq(1)
      expect(assigns(:knowledge_base_case_studies)).to include(KnowledgeItem.find_by(title: 'Test Case Study'))
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get new_admins_additional_knowledge_path
      expect(response).to have_http_status(:success)
    end

    it "assigns a new additional_knowledge" do
      get new_admins_additional_knowledge_path
      expect(assigns(:additional_knowledge)).to be_a_new(AdditionalKnowledge)
    end
  end

  describe "POST /create" do
    let(:valid_attributes) { { title: "Test Knowledge", content: "Test content" } }
    let(:invalid_attributes) { { title: "", content: "" } }

    context "with valid parameters" do
      it "creates a new AdditionalKnowledge" do
        expect {
          post admins_additional_knowledges_path, params: { additional_knowledge: valid_attributes }
        }.to change(AdditionalKnowledge, :count).by(1)
      end

      it "redirects to edit page for HTML requests" do
        post admins_additional_knowledges_path, params: { additional_knowledge: valid_attributes }
        expect(response).to redirect_to(edit_admins_additional_knowledge_path(AdditionalKnowledge.last))
      end

      it "redirects to index for turbo_stream requests" do
        post admins_additional_knowledges_path, params: { additional_knowledge: valid_attributes }, 
             headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        expect(response).to redirect_to(admins_additional_knowledges_path)
      end

      it "sets a success notice" do
        post admins_additional_knowledges_path, params: { additional_knowledge: valid_attributes }
        expect(flash[:notice]).to eq('Additional knowledge was successfully created.')
      end
    end

    context "with invalid parameters" do
      it "does not create a new AdditionalKnowledge" do
        expect {
          post admins_additional_knowledges_path, params: { additional_knowledge: invalid_attributes }
        }.not_to change(AdditionalKnowledge, :count)
      end

      it "renders new template for HTML requests" do
        post admins_additional_knowledges_path, params: { additional_knowledge: invalid_attributes }
        expect(response).to render_template(:new)
      end

    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get edit_admins_additional_knowledge_path(additional_knowledge)
      expect(response).to have_http_status(:success)
    end

    it "assigns the requested additional_knowledge" do
      get edit_admins_additional_knowledge_path(additional_knowledge)
      expect(assigns(:additional_knowledge)).to eq(additional_knowledge)
    end
  end

  describe "PATCH /update" do
    let(:new_attributes) { { title: "Updated Title", content: "Updated content" } }
    let(:invalid_attributes) { { title: "", content: "" } }

    context "with valid parameters" do
      it "updates the requested additional_knowledge" do
        patch admins_additional_knowledge_path(additional_knowledge), params: { additional_knowledge: new_attributes }
        additional_knowledge.reload
        expect(additional_knowledge.title).to eq("Updated Title")
        expect(additional_knowledge.content).to eq("Updated content")
      end

      it "redirects to show page for HTML requests" do
        patch admins_additional_knowledge_path(additional_knowledge), params: { additional_knowledge: new_attributes }
        expect(response).to redirect_to(admins_additional_knowledge_path(additional_knowledge))
      end

      it "redirects to index for turbo_stream requests" do
        patch admins_additional_knowledge_path(additional_knowledge), params: { additional_knowledge: new_attributes },
              headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        expect(response).to redirect_to(admins_additional_knowledges_path)
      end

      it "sets a success notice" do
        patch admins_additional_knowledge_path(additional_knowledge), params: { additional_knowledge: new_attributes }
        expect(flash[:notice]).to eq('Additional knowledge was successfully updated.')
      end
    end

    context "with invalid parameters" do
      it "renders edit template for HTML requests" do
        patch admins_additional_knowledge_path(additional_knowledge), params: { additional_knowledge: invalid_attributes }
        expect(response).to render_template(:edit)
      end

    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested additional_knowledge" do
      additional_knowledge
      expect {
        delete admins_additional_knowledge_path(additional_knowledge)
      }.to change(AdditionalKnowledge, :count).by(-1)
    end

    it "redirects to the additional_knowledges list" do
      delete admins_additional_knowledge_path(additional_knowledge)
      expect(response).to redirect_to(admins_additional_knowledges_path)
    end

    it "sets a success notice" do
      delete admins_additional_knowledge_path(additional_knowledge)
      expect(flash[:notice]).to eq('Additional knowledge was successfully deleted.')
    end
  end

  describe "POST /update_knowledge_base" do
    it "calls KnowledgeImportService" do
      service = double('KnowledgeImportService')
      allow(KnowledgeImportService).to receive(:new).and_return(service)
      allow(service).to receive(:import_all).and_return(true)

      post update_knowledge_base_admins_additional_knowledges_path
      
      expect(service).to have_received(:import_all)
    end

    it "redirects with success notice when import succeeds" do
      allow_any_instance_of(KnowledgeImportService).to receive(:import_all).and_return(true)

      post update_knowledge_base_admins_additional_knowledges_path
      
      expect(response).to redirect_to(admins_additional_knowledges_path)
      expect(flash[:notice]).to eq('Knowledge base updated successfully!')
    end

    it "redirects with error notice when import fails" do
      allow_any_instance_of(KnowledgeImportService).to receive(:import_all).and_return(false)

      post update_knowledge_base_admins_additional_knowledges_path
      
      expect(response).to redirect_to(admins_additional_knowledges_path)
      expect(flash[:alert]).to eq('Knowledge base update failed. Check logs for details.')
    end

    it "handles exceptions gracefully" do
      allow_any_instance_of(KnowledgeImportService).to receive(:import_all).and_raise(StandardError.new("Test error"))

      post update_knowledge_base_admins_additional_knowledges_path
      
      expect(response).to redirect_to(admins_additional_knowledges_path)
      expect(flash[:alert]).to eq('Knowledge base update failed: Test error')
    end
  end
end
