require "rails_helper"

RSpec.describe Document, type: :model do
  describe "validations" do
    it { should validate_presence_of(:title) }
  end

  describe "friendly_id" do
    let(:document) { create(:document, title: "Test Document") }

    it "generates a URL-friendly slug from title" do
      expect(document.slug).to eq("test-document")
    end

    it "updates slug when title changes" do
      document.update(title: "Updated Document")
      expect(document.slug).to eq("updated-document")
    end
  end

  describe "#parsed_content" do
    let(:document) { create(:document, content_markdown: "# Hello\n\nThis is **bold** text.") }
    
    it "converts markdown to HTML" do
      expect(document.parsed_content).to include("<h1>")
      expect(document.parsed_content).to include("<strong>")
    end

    it "returns empty string when content_markdown is blank" do
      document = create(:document, content_markdown: nil)
      expect(document.parsed_content).to eq("")
    end

    it "returns empty string when content_markdown is empty" do
      document = create(:document, content_markdown: "")
      expect(document.parsed_content).to eq("")
    end
  end

  describe "#should_generate_new_friendly_id?" do
    let(:document) { create(:document, title: "Original Title") }

    it "returns true when title changes" do
      document.title = "New Title"
      expect(document.should_generate_new_friendly_id?).to be true
    end

    it "returns false when title doesn't change" do
      expect(document.should_generate_new_friendly_id?).to be false
    end
  end
end

