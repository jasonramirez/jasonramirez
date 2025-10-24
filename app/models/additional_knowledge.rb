class AdditionalKnowledge < ActiveRecord::Base
  validates :title, presence: true
  validates :content, presence: true

  after_save :generate_embedding, if: :saved_change_to_content?

  scope :by_category, ->(category) { where(category: category) }
  scope :by_created, -> { order(created_at: :desc) }
  scope :for_ai, -> { where.not(content_embedding: nil) }
  scope :with_embeddings, -> { where.not(content_embedding: nil) }

  # content_embedding is a vector column - no serialization needed

  def self.search_by_similarity(query, limit: 5)
    return none if query.blank?

    embedding = EmbeddingService.new.generate_embedding(query)
    return none unless embedding

    # For now, return records with embeddings (similarity search requires pgvector)
    # TODO: Implement proper similarity search when pgvector is available
    where.not(content_embedding: nil).limit(limit)
  end

  def generate_embeddings
    return if content.blank?
    
    embedding_service = EmbeddingService.new
    content_emb = embedding_service.generate_embedding(content)
    
    if content_emb
      update_column(:content_embedding, content_emb)
    end
  end

  private

  def generate_embedding
    return if content.blank?

    embedding = EmbeddingService.new.generate_embedding(content)
    update_column(:content_embedding, embedding) if embedding
  end
end
