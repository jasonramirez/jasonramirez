class AdditionalKnowledge < ActiveRecord::Base
  validates :title, presence: true
  validates :content, presence: true

  after_save :generate_embedding, if: :saved_change_to_content?

  scope :by_category, ->(category) { where(category: category) }
  scope :by_created, -> { order(created_at: :desc) }
  scope :for_ai, -> { where.not(content_embedding: nil) }

  def self.search_by_similarity(query, limit: 5)
    return none if query.blank?

    embedding = EmbeddingService.new.generate_embedding(query)
    return none unless embedding

    formatted_embedding = "[#{embedding.join(',')}]"
    where.not(content_embedding: nil)
         .order(Arel.sql("content_embedding <-> '#{formatted_embedding}'"))
         .limit(limit)
  end

  private

  def generate_embedding
    return if content.blank?

    embedding = EmbeddingService.new.generate_embedding(content)
    update_column(:content_embedding, format_embedding_for_db(embedding)) if embedding
  end

  def format_embedding_for_db(embedding)
    return nil unless embedding.is_a?(Array)
    "[#{embedding.join(',')}]"
  end
end
