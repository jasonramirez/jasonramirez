require "rails_helper"

RSpec.describe Admins::DocumentsController, type: :controller do
  let(:admin) { create(:admin) }
  let(:documents_path) { Rails.root.join('app', 'views', 'admins', 'documents') }
  
  before do
    sign_in admin
    
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

  describe "GET #index" do
    it "returns a successful response" do
      get :index
      expect(response).to be_successful
    end

    it "assigns available documents" do
      get :index
      expect(assigns(:documents)).to be_an(Array)
      expect(assigns(:documents)).to include("resume", "cover_letter", "test_doc")
    end

    it "excludes index from documents list" do
      get :index
      expect(assigns(:documents)).not_to include("index")
    end
    
    it "only includes files that actually exist" do
      get :index
      assigned_docs = assigns(:documents)
      
      assigned_docs.each do |doc|
        expect(File.exist?(documents_path.join("#{doc}.html.erb"))).to be true
      end
    end
  end

  describe "GET #show" do
    context "with a valid document" do
      it "returns a successful response for resume" do
        get :show, params: { document: "resume" }
        expect(response).to be_successful
      end

      it "returns a successful response for cover_letter" do
        get :show, params: { document: "cover_letter" }
        expect(response).to be_successful
      end

      it "returns a successful response for page_1" do
        get :show, params: { document: "page_1" }
        expect(response).to be_successful
      end

      it "assigns the document parameter" do
        get :show, params: { document: "resume" }
        expect(assigns(:document)).to eq("resume")
      end

      it "uses the documents layout" do
        get :show, params: { document: "resume" }
        expect(response).to render_template(layout: "documents")
      end

      it "renders the specific document template" do
        get :show, params: { document: "resume" }
        expect(response).to render_template("admins/documents/resume")
      end

      it "renders the correct template for cover_letter" do
        get :show, params: { document: "cover_letter" }
        expect(response).to render_template("admins/documents/cover_letter")
      end
    end

    context "with an invalid document" do
      it "redirects to index with an alert" do
        get :show, params: { document: "nonexistent" }
        expect(response).to redirect_to(admins_documents_path)
        expect(flash[:alert]).to eq("Document not found")
      end
    end
  end

  describe "authentication" do
    before do
      sign_out admin
    end

    it "redirects to admin sign in for index" do
      get :index
      expect(response).to redirect_to(new_admin_session_path)
    end

    it "redirects to admin sign in for show" do
      get :show, params: { document: "resume" }
      expect(response).to redirect_to(new_admin_session_path)
    end
  end

  describe "available_documents private method" do
    it "finds HTML erb files in the documents directory" do
      controller_instance = described_class.new
      documents = controller_instance.send(:available_documents)
      
      expect(documents).to be_an(Array)
      expect(documents).to include("resume", "cover_letter", "page_1")
      expect(documents).not_to include("index")
    end
  end

  describe "template_exists? private method" do
    it "returns true for existing documents" do
      controller_instance = described_class.new
      controller_instance.instance_variable_set(:@lookup_context, controller.lookup_context)
      
      expect(controller_instance.send(:template_exists?, "resume")).to be true
      expect(controller_instance.send(:template_exists?, "cover_letter")).to be true
      expect(controller_instance.send(:template_exists?, "page_1")).to be true
    end

    it "returns false for non-existing documents" do
      controller_instance = described_class.new
      controller_instance.instance_variable_set(:@lookup_context, controller.lookup_context)
      
      expect(controller_instance.send(:template_exists?, "nonexistent")).to be false
    end
  end
end
