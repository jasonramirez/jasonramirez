require 'rails_helper'

RSpec.describe AdditionalKnowledge, type: :model do
  describe 'validations' do
    it 'validates presence of title' do
      additional_knowledge = build(:additional_knowledge, title: nil)
      expect(additional_knowledge).not_to be_valid
      expect(additional_knowledge.errors[:title]).to include("can't be blank")
    end

    it 'validates presence of content' do
      additional_knowledge = build(:additional_knowledge, content: nil)
      expect(additional_knowledge).not_to be_valid
      expect(additional_knowledge.errors[:content]).to include("can't be blank")
    end

    it 'is valid with valid attributes' do
      additional_knowledge = build(:additional_knowledge)
      expect(additional_knowledge).to be_valid
    end
  end

  describe 'scopes' do
    let!(:knowledge1) { create(:additional_knowledge, title: 'First Knowledge') }
    let!(:knowledge2) { create(:additional_knowledge, title: 'Second Knowledge') }

    describe '.by_created' do
      it 'orders by created_at desc' do
        expect(AdditionalKnowledge.by_created).to eq([knowledge2, knowledge1])
      end
    end

    describe '.for_ai' do
      it 'returns only records with content_embedding' do
        # Clear any existing embeddings first
        AdditionalKnowledge.update_all(content_embedding: nil)
        
        embedding = Array.new(1536, 0.1)
        knowledge1.update_column(:content_embedding, embedding)
        expect(AdditionalKnowledge.for_ai).to include(knowledge1)
        expect(AdditionalKnowledge.for_ai).not_to include(knowledge2)
      end
    end
  end

  describe '.search_by_similarity' do
    let!(:knowledge_with_embedding) do
      create(:additional_knowledge, title: 'Design Principles', content: 'Great design principles')
    end

    before do
      # Create a valid 1536-dimension embedding
      embedding = Array.new(1536, 0.1)
      knowledge_with_embedding.update_column(:content_embedding, embedding)
    end

    it 'returns none for blank query' do
      expect(AdditionalKnowledge.search_by_similarity('')).to be_empty
      expect(AdditionalKnowledge.search_by_similarity(nil)).to be_empty
    end

    it 'returns similar knowledge items' do
      embedding = Array.new(1536, 0.1)
      allow_any_instance_of(EmbeddingService).to receive(:generate_embedding).and_return(embedding)
      
      results = AdditionalKnowledge.search_by_similarity('design')
      expect(results).to include(knowledge_with_embedding)
    end

    it 'respects limit parameter' do
      embedding = Array.new(1536, 0.1)
      allow_any_instance_of(EmbeddingService).to receive(:generate_embedding).and_return(embedding)
      
      results = AdditionalKnowledge.search_by_similarity('design', limit: 1)
      expect(results.count).to eq(1)
    end

    it 'returns none when embedding service fails' do
      allow_any_instance_of(OllamaEmbeddingService).to receive(:generate_embedding).and_return(nil)
      
      results = AdditionalKnowledge.search_by_similarity('design')
      expect(results).to be_empty
    end
  end

  describe 'callbacks' do
    it 'generates embedding after save when content changes' do
      embedding = Array.new(1536, 0.1)
      allow_any_instance_of(OllamaEmbeddingService).to receive(:generate_embedding).and_return(embedding)
      
      additional_knowledge = create(:additional_knowledge, content: 'Initial content')
      expect(additional_knowledge.content_embedding).to eq(embedding)
    end

    it 'does not generate embedding when content does not change' do
      additional_knowledge = create(:additional_knowledge, content: 'Initial content')
      embedding = Array.new(1536, 0.1)
      additional_knowledge.update_column(:content_embedding, embedding)
      
      expect_any_instance_of(EmbeddingService).not_to receive(:generate_embedding)
      additional_knowledge.update(title: 'New title')
    end

    it 'does not generate embedding for blank content' do
      expect_any_instance_of(EmbeddingService).not_to receive(:generate_embedding)
      # Skip validation to test the callback behavior
      additional_knowledge = build(:additional_knowledge, content: '')
      additional_knowledge.save(validate: false)
    end
  end

end
