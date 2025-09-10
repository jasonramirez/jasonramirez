require "rails_helper"

RSpec.describe Admins::DocumentsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/admins/documents").to route_to("admins/documents#index")
    end

    it "routes to #show with document parameter" do
      expect(get: "/admins/documents/resume").to route_to(
        "admins/documents#show", 
        document: "resume"
      )
    end

    it "routes to #show with underscored document names" do
      expect(get: "/admins/documents/cover_letter").to route_to(
        "admins/documents#show", 
        document: "cover_letter"
      )
    end

    it "routes to #show with numbered document names" do
      expect(get: "/admins/documents/page_1").to route_to(
        "admins/documents#show", 
        document: "page_1"
      )
    end

    it "generates correct paths" do
      expect(admins_documents_path).to eq("/admins/documents")
      expect(admins_document_path("resume")).to eq("/admins/documents/resume")
      expect(admins_document_path("cover_letter")).to eq("/admins/documents/cover_letter")
    end
  end
end
