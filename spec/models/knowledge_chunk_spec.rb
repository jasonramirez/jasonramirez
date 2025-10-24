require 'rails_helper'

RSpec.describe KnowledgeChunk, type: :model do
  describe "validations" do
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:chunk_index) }
  end

  describe "associations" do
    it { should belong_to(:knowledge_item) }
  end

  describe "scopes" do
    let!(:knowledge_item) { create(:knowledge_item) }
    let!(:chunk1) { create(:knowledge_chunk, knowledge_item: knowledge_item, category: 'Blog Post') }
    let!(:chunk2) { create(:knowledge_chunk, knowledge_item: knowledge_item, category: 'Case Study') }
    let!(:chunk_with_embedding) { create(:knowledge_chunk, knowledge_item: knowledge_item) }

    before do
      # Simulate having an embedding
        # Create a valid 3072-dimension embedding
        embedding = Array.new(3072, 0.1)
        chunk_with_embedding.update_column(:content_embedding, "[#{embedding.join(',')}]")
    end

    describe ".by_category" do
      it "filters by category" do
        expect(KnowledgeChunk.by_category('Blog Post')).to include(chunk1)
        expect(KnowledgeChunk.by_category('Blog Post')).not_to include(chunk2)
      end
    end

    describe ".with_embeddings" do
      it "returns only chunks with embeddings" do
        expect(KnowledgeChunk.with_embeddings).to include(chunk_with_embedding)
        expect(KnowledgeChunk.with_embeddings).not_to include(chunk1)
      end
    end

    describe ".ordered" do
      let!(:specific_knowledge_item) { create(:knowledge_item, title: "Ordering Test Item") }
      let!(:chunk_a) { create(:knowledge_chunk, knowledge_item: specific_knowledge_item, chunk_index: 0) }
      let!(:chunk_b) { create(:knowledge_chunk, knowledge_item: specific_knowledge_item, chunk_index: 1) }

      it "orders by knowledge_item_id and chunk_index" do
        result = KnowledgeChunk.ordered.where(knowledge_item: specific_knowledge_item)
        expect(result.to_a).to eq([chunk_a, chunk_b])
      end
    end
  end

  describe "embedding generation" do
    let(:knowledge_item) { create(:knowledge_item) }
    let(:chunk) { build(:knowledge_chunk, knowledge_item: knowledge_item) }

    describe "#should_generate_embeddings?" do
      context "when content is present and no embedding exists" do
        it "returns true" do
          expect(chunk.send(:should_generate_embeddings?)).to be true
        end
      end

      context "when content is blank" do
        before { chunk.content = "" }

        it "returns false" do
          expect(chunk.send(:should_generate_embeddings?)).to be false
        end
      end

      context "when embedding already exists" do
        before { chunk.content_embedding = '[0.1,0.2,0.3]' }

        it "returns false" do
          expect(chunk.send(:should_generate_embeddings?)).to be false
        end
      end
    end

    describe "callbacks" do
      it "triggers embedding generation after save" do
        chunk = build(:knowledge_chunk, knowledge_item: knowledge_item)
        
        expect(chunk).to receive(:generate_embeddings_async)
        chunk.save!
      end
    end
  end

  describe ".semantic_search" do
    context "when query is blank" do
      it "returns empty array" do
        expect(KnowledgeChunk.semantic_search("")).to eq([])
      end
    end

    context "when embedding service fails" do
      before do
        embedding_service = instance_double(EmbeddingService)
        allow(EmbeddingService).to receive(:new).and_return(embedding_service)
        allow(embedding_service).to receive(:generate_embedding).and_return(nil)
      end

      it "returns empty array" do
        expect(KnowledgeChunk.semantic_search("test query")).to eq([])
      end
    end

    context "with valid embeddings", :skip_embedding_test do
    end
  end

  describe "#format_embedding_for_db" do
    let(:knowledge_item) { create(:knowledge_item) }
    let(:chunk) { create(:knowledge_chunk, knowledge_item: knowledge_item) }

    it "formats array as PostgreSQL array string" do
      embedding = [0.1, 0.2, 0.3]
      result = chunk.send(:format_embedding_for_db, embedding)
      expect(result).to eq('[0.1,0.2,0.3]')
    end

    it "returns nil for non-array input" do
      result = chunk.send(:format_embedding_for_db, "not an array")
      expect(result).to be_nil
    end
  end
end
