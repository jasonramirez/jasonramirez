require "rails_helper"

RSpec.describe Admins::DocumentsController, type: :controller do
  let(:admin) { create(:admin) }
  
  before do
    sign_in admin, scope: :admin
  end

  describe "GET #index" do
    let!(:document1) { create(:document, title: "Document A") }
    let!(:document2) { create(:document, title: "Document B") }

    it "returns a successful response" do
      get :index
      expect(response).to be_successful
    end

    it "assigns all documents ordered by title" do
      get :index
      expect(assigns(:documents)).to eq([document1, document2])
    end
  end

  describe "GET #show" do
    let(:document) { create(:document, title: "Test Document") }

    it "returns a successful response" do
      document.reload # Ensure slug is set
      get :show, params: { id: document.slug }
      expect(response).to be_successful
    end

    it "assigns the requested document" do
      document.reload # Ensure slug is set
      get :show, params: { id: document.slug }
      expect(assigns(:document)).to eq(document)
    end

    it "renders with documents layout" do
      document.reload # Ensure slug is set
      get :show, params: { id: document.slug }
      expect(response).to render_template(layout: "documents")
    end
  end

  describe "GET #new" do
    it "returns a successful response" do
      get :new
      expect(response).to be_successful
    end

    it "assigns a new document" do
      get :new
      expect(assigns(:document)).to be_a_new(Document)
    end
  end

  describe "POST #create" do
    let(:valid_attributes) do
      {
        title: "New Document",
        content_markdown: "# New Document\n\nContent here."
      }
    end

    let(:invalid_attributes) do
      {
        title: "",
        content_markdown: "Content without title"
      }
    end

    context "with valid parameters" do
      it "creates a new document" do
        expect {
          post :create, params: { document: valid_attributes }
        }.to change(Document, :count).by(1)
      end

      it "redirects to the edit page" do
        post :create, params: { document: valid_attributes }
        created_document = Document.last
        expect(response).to redirect_to(edit_admins_document_path(created_document))
      end

      it "sets a success flash message" do
        post :create, params: { document: valid_attributes }
        expect(flash[:notice]).to be_present
      end
    end

    context "with invalid parameters" do
      it "does not create a new document" do
        expect {
          post :create, params: { document: invalid_attributes }
        }.not_to change(Document, :count)
      end

      it "redirects to new document path" do
        post :create, params: { document: invalid_attributes }
        expect(response).to redirect_to(new_admins_document_path)
      end

      it "sets an error flash message" do
        post :create, params: { document: invalid_attributes }
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "GET #edit" do
    let(:document) { create(:document) }

    it "returns a successful response" do
      document.reload # Ensure slug is set
      get :edit, params: { id: document.slug }
      expect(response).to be_successful
    end

    it "assigns the requested document" do
      document.reload # Ensure slug is set
      get :edit, params: { id: document.slug }
      expect(assigns(:document)).to eq(document)
    end
  end

  describe "PATCH #update" do
    let(:document) { create(:document, title: "Original Title", content_markdown: "Original content") }
    let(:valid_attributes) { { title: "Updated Title", content_markdown: "Updated content" } }
    let(:invalid_attributes) { { title: "" } }

    context "with valid parameters" do
      it "updates the document" do
        patch :update, params: { id: document.slug, document: valid_attributes }
        document.reload
        expect(document.title).to eq("Updated Title")
        expect(document.content_markdown).to eq("Updated content")
      end

      it "redirects to the edit page" do
        patch :update, params: { id: document.slug, document: valid_attributes }
        document.reload
        # After title update, slug changes, so check redirect includes edit path
        expect(response).to redirect_to(edit_admins_document_path(document.reload))
      end

      it "sets a success flash message" do
        patch :update, params: { id: document.slug, document: valid_attributes }
        expect(flash[:notice]).to be_present
      end
    end

    context "with invalid parameters" do
      it "does not update the document" do
        patch :update, params: { id: document.slug, document: invalid_attributes }
        document.reload
        expect(document.title).to eq("Original Title")
      end

      it "redirects to edit page" do
        original_slug = document.slug
        patch :update, params: { id: original_slug, document: invalid_attributes }
        # Check that it redirects to an edit path (may use ID if slug lookup fails)
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include("/admins/documents/")
        expect(response.location).to include("/edit")
      end

      it "sets an error flash message" do
        patch :update, params: { id: document.slug, document: invalid_attributes }
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:document) { create(:document) }

    it "destroys the document" do
      expect {
        delete :destroy, params: { id: document.slug }
      }.to change(Document, :count).by(-1)
    end

    it "redirects to documents index" do
      delete :destroy, params: { id: document.slug }
      expect(response).to redirect_to(admins_documents_path)
    end

    it "sets a success flash message" do
      delete :destroy, params: { id: document.slug }
      expect(flash[:notice]).to be_present
    end
  end

  describe "authentication" do
    before do
      sign_out admin
    end

    it "requires authentication for index" do
      get :index
      expect(response).to redirect_to(new_admin_session_path)
    end

    it "requires authentication for show" do
      document = create(:document)
      get :show, params: { id: document.slug }
      expect(response).to redirect_to(new_admin_session_path)
    end

    it "requires authentication for new" do
      get :new
      expect(response).to redirect_to(new_admin_session_path)
    end

    it "requires authentication for create" do
      post :create, params: { document: { title: "Test" } }
      expect(response).to redirect_to(new_admin_session_path)
    end

    it "requires authentication for edit" do
      document = create(:document)
      get :edit, params: { id: document.slug }
      expect(response).to redirect_to(new_admin_session_path)
    end

    it "requires authentication for update" do
      document = create(:document)
      patch :update, params: { id: document.slug, document: { title: "Updated" } }
      expect(response).to redirect_to(new_admin_session_path)
    end

    it "requires authentication for destroy" do
      document = create(:document)
      delete :destroy, params: { id: document.slug }
      expect(response).to redirect_to(new_admin_session_path)
    end
  end
end

