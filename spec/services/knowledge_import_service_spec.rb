require "rails_helper"

RSpec.describe KnowledgeImportService do
  let(:service) { described_class.new }
  let!(:published_post) { create(:post, title: "Published Post", published: true, post_text: "Published content") }
  let!(:unpublished_post) { create(:post, title: "Draft Post", published: false, post_text: "Draft content") }

  describe "#initialize" do
    it "sets default directory path" do
      service = described_class.new
      expected_path = Rails.root.join('app', 'assets', 'knowledge')
      expect(service.instance_variable_get(:@directory_path)).to eq(expected_path)
    end

    it "accepts custom directory path" do
      custom_path = "/custom/path"
      service = described_class.new(custom_path)
      expect(service.instance_variable_get(:@directory_path)).to eq(custom_path)
    end
  end

  describe "#import_all" do
    before do
      # Mock the chunk generation queue to avoid background job complexity
      allow(service).to receive(:queue_chunk_generation)
    end

    it "calls import methods for posts and case studies" do
      expect(service).to receive(:import_published_posts).and_return([1])
      expect(service).to receive(:import_case_studies).and_return([2])
      expect(service).to receive(:queue_chunk_generation).with([1, 2])
      
      service.import_all
    end

    it "queues chunk generation for imported items" do
      allow(service).to receive(:import_published_posts).and_return([1, 2])
      allow(service).to receive(:import_case_studies).and_return([3])
      
      expect(service).to receive(:queue_chunk_generation).with([1, 2, 3])
      service.import_all
    end
  end

  describe "#import_published_posts" do
    it "imports only published posts" do
      expect {
        service.import_published_posts
      }.to change(KnowledgeItem, :count).by(1)
      
      imported_item = KnowledgeItem.find_by(title: published_post.title)
      expect(imported_item).to be_present
      expect(imported_item.content).to eq(published_post.post_text)
      expect(imported_item.category).to eq("Blog Post")
      expect(imported_item.source).to eq("post_#{published_post.id}")
    end

    it "does not import unpublished posts" do
      service.import_published_posts
      
      unpublished_item = KnowledgeItem.find_by(title: unpublished_post.title)
      expect(unpublished_item).to be_nil
    end

    it "updates existing knowledge items" do
      # Create existing knowledge item
      existing_item = create(:knowledge_item, 
        title: published_post.title,
        content: "Old content",
        source: "post_#{published_post.id}"
      )

      expect {
        service.import_published_posts
      }.not_to change(KnowledgeItem, :count)

      existing_item.reload
      expect(existing_item.content).to eq(published_post.post_text)
      expect(existing_item.last_updated).to be_present
    end

    it "returns array of imported knowledge item IDs" do
      ids = service.import_published_posts
      expect(ids).to be_an(Array)
      expect(ids.length).to eq(1)
      expect(ids.first).to be_a(Integer)
    end

    it "handles posts with blank content gracefully" do
      blank_post = create(:post, title: "Blank Post", published: true, post_text: "", post_markdown: "")
      
      expect {
        service.import_published_posts
      }.to raise_error(ActiveRecord::RecordInvalid, /Content can't be blank/)
      
      # Should not create the item with empty content
      blank_item = KnowledgeItem.find_by(title: blank_post.title)
      expect(blank_item).to be_nil
    end
  end

  describe "#import_case_studies" do
    before do
      # Mock file existence checks
      allow(File).to receive(:exist?).and_return(false)
      allow(File).to receive(:exist?).with("app/views/works/_dropbox_keeping_flow.html.erb").and_return(true)
      allow(File).to receive(:exist?).with("app/views/works/_mayo_gamifying_medical_education.html.erb").and_return(true)
      
      # Mock file reading
      allow(File).to receive(:read).with("app/views/works/_dropbox_keeping_flow.html.erb").and_return("<h1>Dropbox Flow</h1><p>Content about flow</p>")
      allow(File).to receive(:read).with("app/views/works/_mayo_gamifying_medical_education.html.erb").and_return("<h1>Mayo Education</h1><p>Content about education</p>")
      
      # Mock file modification time
      allow(File).to receive(:mtime).and_return(1.day.ago)
    end

    it "imports case studies from hardcoded list" do
      expect {
        service.import_case_studies
      }.to change(KnowledgeItem, :count).by(2)
      
      dropbox_study = KnowledgeItem.find_by(title: "Dropbox Keeping Flow")
      expect(dropbox_study).to be_present
      expect(dropbox_study.category).to eq("Case Study")
      expect(dropbox_study.content).to include("Dropbox Flow")
    end

    it "returns array of imported knowledge item IDs" do
      ids = service.import_case_studies
      expect(ids).to be_an(Array)
      expect(ids.length).to eq(2)
      expect(ids.all? { |id| id.is_a?(Integer) }).to be true
    end

    context "when no case studies files exist" do
      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      it "returns empty array" do
        ids = service.import_case_studies
        expect(ids).to eq([])
      end

      it "does not create any knowledge items" do
        expect {
          service.import_case_studies
        }.not_to change(KnowledgeItem, :count)
      end
    end
  end

  describe "#queue_chunk_generation" do
    let(:knowledge_item) { create(:knowledge_item) }

    it "enqueues GenerateChunksJob for each item" do
      expect(GenerateChunksJob).to receive(:perform_later).with(knowledge_item.id)
      
      service.send(:queue_chunk_generation, [knowledge_item.id])
    end

    it "handles multiple items" do
      item1 = create(:knowledge_item)
      item2 = create(:knowledge_item)
      
      expect(GenerateChunksJob).to receive(:perform_later).with(item1.id)
      expect(GenerateChunksJob).to receive(:perform_later).with(item2.id)
      
      service.send(:queue_chunk_generation, [item1.id, item2.id])
    end

    it "handles empty array gracefully" do
      expect(GenerateChunksJob).not_to receive(:perform_later)
      
      service.send(:queue_chunk_generation, [])
    end
  end

end
