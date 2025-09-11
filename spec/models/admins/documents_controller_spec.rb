require "rails_helper"

RSpec.describe Admins::DocumentsController, type: :controller do
  let(:documents_path) { Rails.root.join('app', 'views', 'admins', 'documents') }
  
  before do
    # Ensure documents directory exists
    FileUtils.mkdir_p(documents_path)
    
    # Create test document files
    File.write(documents_path.join('resume.html.erb'), '<h1>Resume</h1>')
    File.write(documents_path.join('cover_letter.html.erb'), '<h1>Cover Letter</h1>')
    File.write(documents_path.join('test_doc.html.erb'), '<h1>Test Document</h1>')
    File.write(documents_path.join('index.html.erb'), '<h1>Index</h1>')
  end
  
  after do
    # Clean up test files
    FileUtils.rm_rf(documents_path) if documents_path.exist?
  end

  describe "private methods" do
    let(:controller_instance) { described_class.new }

    describe "#available_documents" do
      it "finds HTML erb files in the documents directory" do
        documents = controller_instance.send(:available_documents)
        
        expect(documents).to be_an(Array)
        expect(documents).to include("resume", "cover_letter", "test_doc")
        expect(documents).not_to include("index")
      end

      it "only includes files that actually exist" do
        documents = controller_instance.send(:available_documents)
        
        documents.each do |doc|
          expect(File.exist?(documents_path.join("#{doc}.html.erb"))).to be true
        end
      end

      it "excludes index from documents list" do
        documents = controller_instance.send(:available_documents)
        expect(documents).not_to include("index")
      end
    end

    describe "#document_file_exists?" do
      it "returns true for existing documents" do
        expect(controller_instance.send(:document_file_exists?, "resume")).to be true
        expect(controller_instance.send(:document_file_exists?, "cover_letter")).to be true
        expect(controller_instance.send(:document_file_exists?, "test_doc")).to be true
      end

      it "returns false for non-existing documents" do
        expect(controller_instance.send(:document_file_exists?, "nonexistent")).to be false
      end
    end
  end
end
