require "rails_helper"

RSpec.describe "Admin Documents", type: :request do
  let(:admin) { create(:admin) }

  describe "GET /admins/documents" do
    context "when authenticated" do
      before do
        sign_in_admin(admin)
      end

      let!(:document1) { create(:document, title: "Document A") }
      let!(:document2) { create(:document, title: "Document B") }

      it "returns a successful response" do
        get admins_documents_path
        expect(response).to be_successful
      end

      it "shows the documents index page" do
        get admins_documents_path
        expect(response.body).to include("Documents")
      end

      it "displays all documents" do
        get admins_documents_path
        expect(response.body).to include("Document A")
        expect(response.body).to include("Document B")
      end

      it "shows document count" do
        get admins_documents_path
        expect(response.body).to include("2 documents")
      end
    end

    context "when not authenticated" do
      it "redirects to admin sign in" do
        get admins_documents_path
        expect(response).to redirect_to(new_admin_session_path)
      end
    end
  end

  describe "GET /admins/documents/:id" do
    let(:document) { create(:document, title: "Test Document", content_markdown: "# Test Document\n\nThis is **test** content.") }

    context "when authenticated" do
      before do
        sign_in_admin(admin)
      end

      it "returns a successful response" do
        get admins_document_path(document)
        expect(response).to be_successful
      end

      it "shows the document content" do
        get admins_document_path(document)
        expect(response.body).to include("Test Document")
        expect(response.body).to include("<strong>")
      end

      it "renders markdown as HTML" do
        get admins_document_path(document)
        expect(response.body).to include("<h1>")
      end
    end

    context "when not authenticated" do
      it "redirects to admin sign in" do
        get admins_document_path(document)
        expect(response).to redirect_to(new_admin_session_path)
      end
    end
  end

  describe "GET /admins/documents/new" do
    context "when authenticated" do
      before do
        sign_in_admin(admin)
      end

      it "returns a successful response" do
        get new_admins_document_path
        expect(response).to be_successful
      end

      it "shows the new document form" do
        get new_admins_document_path
        expect(response.body).to include("New Document")
      end
    end

    context "when not authenticated" do
      it "redirects to admin sign in" do
        get new_admins_document_path
        expect(response).to redirect_to(new_admin_session_path)
      end
    end
  end

  describe "POST /admins/documents" do
    context "when authenticated" do
      before do
        sign_in_admin(admin)
      end

      let(:valid_params) do
        {
          document: {
            title: "New Document",
            content_markdown: "# New Document\n\nContent here."
          }
        }
      end

      it "creates a new document" do
        expect {
          post admins_documents_path, params: valid_params
        }.to change(Document, :count).by(1)
      end

      it "redirects to edit page" do
        post admins_documents_path, params: valid_params
        expect(response).to redirect_to(edit_admins_document_path(Document.last))
      end
    end

    context "when not authenticated" do
      it "redirects to admin sign in" do
        post admins_documents_path, params: { document: { title: "Test" } }
        expect(response).to redirect_to(new_admin_session_path)
      end
    end
  end

  describe "GET /admins/documents/:id/edit" do
    let(:document) { create(:document) }

    context "when authenticated" do
      before do
        sign_in_admin(admin)
      end

      it "returns a successful response" do
        get edit_admins_document_path(document)
        expect(response).to be_successful
      end

      it "shows the edit form" do
        get edit_admins_document_path(document)
        expect(response.body).to include("Edit Document")
      end
    end

    context "when not authenticated" do
      it "redirects to admin sign in" do
        get edit_admins_document_path(document)
        expect(response).to redirect_to(new_admin_session_path)
      end
    end
  end

  describe "PATCH /admins/documents/:id" do
    let(:document) { create(:document, title: "Original Title") }

    context "when authenticated" do
      before do
        sign_in_admin(admin)
      end

      it "updates the document" do
        patch admins_document_path(document), params: {
          document: { title: "Updated Title" }
        }
        document.reload
        expect(document.title).to eq("Updated Title")
      end

      it "redirects to edit page" do
        patch admins_document_path(document), params: {
          document: { title: "Updated Title" }
        }
        document.reload
        expect(response).to redirect_to(edit_admins_document_path(document))
      end
    end

    context "when not authenticated" do
      it "redirects to admin sign in" do
        patch admins_document_path(document), params: {
          document: { title: "Updated Title" }
        }
        expect(response).to redirect_to(new_admin_session_path)
      end
    end
  end

  describe "DELETE /admins/documents/:id" do
    let!(:document) { create(:document) }

    context "when authenticated" do
      before do
        sign_in_admin(admin)
      end

      it "deletes the document" do
        expect {
          delete admins_document_path(document)
        }.to change(Document, :count).by(-1)
      end

      it "redirects to documents index" do
        delete admins_document_path(document)
        expect(response).to redirect_to(admins_documents_path)
      end
    end

    context "when not authenticated" do
      it "redirects to admin sign in" do
        delete admins_document_path(document)
        expect(response).to redirect_to(new_admin_session_path)
      end
    end
  end
end

