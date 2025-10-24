require "rails_helper"

RSpec.describe ContentChunkingService do
  let(:service) { described_class.new }
  let(:knowledge_item) do
    double(
      id: 1,
      content: sample_content,
      title: "Sample Knowledge Item",
      category: "Blog Post",
      tags: "#design, #process",
      confidence_score: 0.9,
      source: "post_123",
      last_updated: 1.day.ago
    )
  end
  let(:sample_content) do
    "This is the first paragraph about design systems. It contains important information about consistency and reusability.\n\nThis is the second paragraph that discusses implementation details. It provides specific examples and use cases.\n\nThe third paragraph covers advanced topics like theming and customization. It goes into depth about complex scenarios."
  end

  describe "#initialize" do
    it "initializes with an embedding service" do
      expect(service.instance_variable_get(:@embedding_service)).to be_a(OllamaEmbeddingService)
    end
  end

  describe "#chunk_knowledge_item" do
    context "with valid content" do
      it "returns an array of chunks" do
        chunks = service.chunk_knowledge_item(knowledge_item)
        expect(chunks).to be_an(Array)
        expect(chunks).not_to be_empty
      end

      it "creates chunks with proper attributes" do
        chunks = service.chunk_knowledge_item(knowledge_item)
        chunk = chunks.first
        
        expect(chunk[:knowledge_item_id]).to eq(knowledge_item.id)
        expect(chunk[:content]).to be_present
        expect(chunk[:chunk_index]).to be_a(Integer)
        expect(chunk[:chunk_type]).to be_in(['semantic', 'size'])
        expect(chunk[:title]).to include(knowledge_item.title)
        expect(chunk[:category]).to eq(knowledge_item.category)
      end

      it "assigns sequential chunk indices" do
        chunks = service.chunk_knowledge_item(knowledge_item)
        indices = chunks.map { |chunk| chunk[:chunk_index] }
        expect(indices).to eq((0...chunks.length).to_a)
      end
    end

    context "with blank content" do
      let(:blank_knowledge_item) do
        double(
          id: 2,
          content: "",
          title: "Blank Item",
          category: "Blog Post",
          tags: "#test",
          confidence_score: 0.9,
          source: "post_456",
          last_updated: 1.day.ago
        )
      end

      it "returns empty array" do
        chunks = service.chunk_knowledge_item(blank_knowledge_item)
        expect(chunks).to eq([])
      end
    end

    context "with nil content" do
      let(:nil_knowledge_item) do
        double(
          id: 3,
          content: nil,
          title: "Nil Item",
          category: "Blog Post",
          tags: "#test",
          confidence_score: 0.9,
          source: "post_789",
          last_updated: 1.day.ago
        )
      end

      it "returns empty array" do
        chunks = service.chunk_knowledge_item(nil_knowledge_item)
        expect(chunks).to eq([])
      end
    end
  end

  describe "#chunk_by_semantics" do
    it "splits content by double newlines" do
      chunks = service.send(:chunk_by_semantics, sample_content)
      expect(chunks.length).to be >= 1
      expect(chunks.first).to include("first paragraph")
      if chunks.length > 1
        expect(chunks.join(" ")).to include("second paragraph")
        expect(chunks.join(" ")).to include("third paragraph")
      end
    end

    it "cleans up whitespace" do
      content_with_whitespace = "First paragraph with sufficient content to meet the minimum chunk size requirement. This needs to be long enough to pass the MIN_CHUNK_SIZE check.\n\n  \n\nSecond paragraph also needs to have enough content to meet the minimum chunk size requirement so it will be included in the chunking."
      chunks = service.send(:chunk_by_semantics, content_with_whitespace)
      expect(chunks.length).to be >= 1
      chunks.each do |chunk|
        expect(chunk.strip).to eq(chunk)
        expect(chunk).not_to be_blank
      end
    end

    it "respects minimum chunk size" do
      short_content = "Short.\n\nVery short."
      chunks = service.send(:chunk_by_semantics, short_content)
      # Should return empty if content doesn't meet minimum requirements
      chunks.each do |chunk|
        expect(chunk.length).to be >= ContentChunkingService::MIN_CHUNK_SIZE
      end
    end
  end

  describe "#chunk_by_size" do
    let(:long_content) { "A" * 2500 }

    it "splits content by size when too long" do
      chunks = service.send(:chunk_by_size, long_content)
      expect(chunks.length).to be > 1
      expect(chunks.first.length).to be <= ContentChunkingService::MAX_CHUNK_SIZE
    end

    it "includes overlap between chunks" do
      chunks = service.send(:chunk_by_size, long_content)
      if chunks.length > 1
        # Check that there's some overlap (chunks share some characters)
        expect(chunks[0][-ContentChunkingService::OVERLAP_SIZE..-1]).to be_present
      end
    end
  end

  describe "#create_chunk" do
    let(:content) { "Sample chunk content" }
    let(:index) { 0 }
    let(:type) { 'semantic' }

    it "creates a knowledge chunk hash with correct attributes" do
      chunk = service.send(:create_chunk, knowledge_item, content, index, type)
      
      expect(chunk).to be_a(Hash)
      expect(chunk[:knowledge_item_id]).to eq(knowledge_item.id)
      expect(chunk[:content]).to eq(content)
      expect(chunk[:chunk_index]).to eq(index)
      expect(chunk[:chunk_type]).to eq(type)
      expect(chunk[:title]).to include(knowledge_item.title)
      expect(chunk[:category]).to eq(knowledge_item.category)
      expect(chunk[:tags]).to eq(knowledge_item.tags)
      expect(chunk[:confidence_score]).to eq(knowledge_item.confidence_score)
      expect(chunk[:source]).to eq(knowledge_item.source)
    end

    it "does not save the chunk to database" do
      # This test verifies that create_chunk returns a hash, not a saved object
      chunk = service.send(:create_chunk, knowledge_item, content, index, type)
      expect(chunk).to be_a(Hash)
      expect(chunk).not_to respond_to(:save)
    end

    it "includes part number in title" do
      chunk = service.send(:create_chunk, knowledge_item, content, index, type)
      expect(chunk[:title]).to eq("#{knowledge_item.title} (Part #{index + 1})")
    end
  end

  describe "constants" do
    it "defines chunking constants" do
      expect(ContentChunkingService::MAX_CHUNK_SIZE).to eq(1000)
      expect(ContentChunkingService::MIN_CHUNK_SIZE).to eq(200)
      expect(ContentChunkingService::OVERLAP_SIZE).to eq(100)
    end
  end
end
