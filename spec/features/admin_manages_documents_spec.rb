require "rails_helper"

feature "Admin manages documents" do
  let(:admin) { create(:admin) }
  
  before do
    sign_in admin
  end

  context "viewing the documents index" do
    it "shows a list of available documents" do
      visit admins_documents_path

      expect(page).to have_text("Documents")
      expect(page).to have_text("Available documents for viewing and printing:")
      
      expect(page).to have_link("Resume", href: admins_document_path("resume"))
      expect(page).to have_link("Cover letter", href: admins_document_path("cover_letter"))
      expect(page).to have_link("Page 1", href: admins_document_path("page_1"))
    end
  end

  context "viewing individual documents" do
    it "displays the resume document" do
      visit admins_document_path("resume")
      
      expect(page).to have_text("Jason Ramirez")
      expect(response.status).to eq(200)
    end

    it "displays the cover letter document" do
      visit admins_document_path("cover_letter")
      
      expect(page).to have_text("Jason Ramirez")
      expect(page).to have_text("jason@jasonramirez.com")
      expect(response.status).to eq(200)
    end

    it "displays the sample page document" do
      visit admins_document_path("page_1")
      
      expect(page).to have_text("Sample Document")
      expect(page).to have_text("/admin/documents/filename")
      expect(response.status).to eq(200)
    end

    it "redirects for non-existent documents" do
      visit admins_document_path("nonexistent")
      
      expect(current_path).to eq(admins_documents_path)
      expect(page).to have_text("Document not found")
    end
  end

  context "document layout and styling" do
    it "uses the documents layout" do
      visit admins_document_path("resume")
      
      # Check for document-specific styling
      expect(page).to have_css(".document")
      
      # Check for proper font loading (via page source)
      expect(page.html).to include("Charter")
      expect(page.html).to include("Passo")
    end

    it "has print-optimized styles" do
      visit admins_document_path("resume")
      
      # Check that print styles are included
      expect(page.html).to include("@media print")
    end
  end

  context "navigation and access" do
    it "allows navigation from index to documents and back" do
      visit admins_documents_path
      
      click_link "Resume"
      expect(current_path).to eq(admins_document_path("resume"))
      
      visit admins_documents_path
      expect(page).to have_text("Documents")
    end
  end

  context "without admin authentication" do
    before do
      sign_out admin
    end

    it "redirects to admin sign in" do
      visit admins_documents_path
      
      expect(current_path).to eq(new_admin_session_path)
    end

    it "redirects to admin sign in for individual documents" do
      visit admins_document_path("resume")
      
      expect(current_path).to eq(new_admin_session_path)
    end
  end
end
