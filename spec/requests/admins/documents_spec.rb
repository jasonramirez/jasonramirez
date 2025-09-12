require "rails_helper"

RSpec.describe "Admin Documents", type: :request do
  let(:admin) { create(:admin) }
  let(:documents_path) { Rails.root.join('app', 'views', 'admins', 'documents') }
  
  before do
    # Ensure documents directory exists
    FileUtils.mkdir_p(documents_path)
    
    # Create test document files
    File.write(documents_path.join('resume.html.erb'), '<h1>Resume</h1><p>Experience</p>')
    File.write(documents_path.join('cover_letter.html.erb'), '<h1>Cover Letter</h1>')
    File.write(documents_path.join('test_doc.html.erb'), '<h1>Test Document</h1>')
    File.write(documents_path.join('index.html.erb'), '<h1>Index</h1>')
  end
  
  after do
    # Clean up test files
    FileUtils.rm_rf(documents_path) if documents_path.exist?
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
        expect(response.body).to include("Index")
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

      it "returns a successful response for resume" do
        get admins_document_path("resume")
        expect(response).to be_successful
      end

      it "returns a successful response for cover_letter" do
        get admins_document_path("cover_letter")
        expect(response).to be_successful
      end

      it "shows the document content" do
        get admins_document_path("resume")
        expect(response.body).to include("Resume")
        expect(response.body).to include("Experience")
      end

      it "redirects when document doesn't exist" do
        get admins_document_path("nonexistent")
        expect(response).to redirect_to(admins_documents_path)
        expect(flash[:alert]).to eq("Document not found")
      end
    end

    context "when not authenticated" do
      it "redirects to admin sign in" do
        get admins_document_path("resume")
        expect(response).to redirect_to(new_admin_session_path)
      end
    end
  end
end
