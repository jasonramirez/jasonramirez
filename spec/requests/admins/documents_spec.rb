require "rails_helper"

RSpec.describe "Admin Documents", type: :request do
  let(:admin) { create(:admin) }
  let(:documents_path) { Rails.root.join('app', 'views', 'admins', 'documents') }
  
  before do
    # Ensure documents directory exists
    FileUtils.mkdir_p(documents_path)
    
    # Create test document file (won't conflict with real documents)
    File.write(documents_path.join('test_doc.html.erb'), '<h1>Test Document</h1><p>Test content.</p>')
  end
  
  after do
    # Clean up only the test document file
    test_file = documents_path.join('test_doc.html.erb')
    File.delete(test_file) if File.exist?(test_file)
  end

  describe "GET /admins/documents" do
    context "when authenticated" do
      before do
        sign_in_admin(admin)
      end

      it "returns a successful response" do
        get admins_documents_path
        expect(response).to be_successful
      end

      it "shows the documents index page" do
        get admins_documents_path
        expect(response.body).to include("Documents")
      end
    end

    context "when not authenticated" do
      it "redirects to admin sign in" do
        get admins_documents_path
        expect(response).to redirect_to(new_admin_session_path)
      end
    end
  end

  describe "GET /admins/documents/:document" do
    context "when authenticated" do
      before do
        sign_in_admin(admin)
      end

      it "returns a successful response for test_doc" do
        get admins_document_path("test_doc")
        expect(response).to be_successful
      end

      it "shows the document content" do
        get admins_document_path("test_doc")
        expect(response.body).to include("Test Document")
        expect(response.body).to include("Test content.")
      end

      it "redirects when document doesn't exist" do
        get admins_document_path("nonexistent")
        expect(response).to redirect_to(admins_documents_path)
        expect(flash[:alert]).to eq("Document not found")
      end
    end

    context "when not authenticated" do
      it "redirects to admin sign in" do
        get admins_document_path("test_doc")
        expect(response).to redirect_to(new_admin_session_path)
      end
    end
  end
end
