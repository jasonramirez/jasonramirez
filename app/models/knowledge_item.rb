class KnowledgeItem < ActiveRecord::Base
  validates :title, presence: true
  validates :content, presence: true
  validates :category, presence: true
  validates :confidence_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: true

  scope :by_category, ->(category) { where(category: category) }
  scope :high_confidence, -> { where('confidence_score >= ?', 0.8) }
  scope :recent, -> { order(last_updated: :desc) }
  scope :with_embeddings, -> { where.not(content_embedding: nil) }

  after_save :generate_embeddings_async, if: :should_generate_embeddings?

  def self.search(query)
    return all if query.blank?

    # Split query into words for better matching
    words = query.downcase.split(/\s+/).reject(&:blank?)
    
    # Build a more flexible search query
    conditions = []
    values = {}
    
    words.each_with_index do |word, index|
      conditions << "(LOWER(title) LIKE :word#{index} OR LOWER(content) LIKE :word#{index} OR LOWER(tags) LIKE :word#{index})"
      values["word#{index}".to_sym] = "%#{word}%"
    end
    
    where(conditions.join(' OR '), values)
  end

  def tags_array
    tags.present? ? tags.split(',').map(&:strip) : []
  end

  def tags_array=(tags_array)
    self.tags = tags_array.reject(&:blank?).join(', ')
  end

  def update_timestamp
    update(last_updated: Time.current)
  end

  # Semantic search using embeddings
  def self.semantic_search(query, limit: 10)
    return [] if query.blank?
    
    embedding_service = EmbeddingService.new
    query_embedding = embedding_service.generate_embedding(query)
    
    return fallback_search(query, limit) if query_embedding.nil?
    
    # Format embedding for database query
    formatted_embedding = "[#{query_embedding.join(',')}]"
    
    # Use pgvector for cosine similarity search with Arel.sql for vector operations
    with_embeddings
      .select(Arel.sql("*, content_embedding <=> '#{formatted_embedding}' AS similarity_score"))
      .order(Arel.sql("content_embedding <=> '#{formatted_embedding}'"))
      .limit(limit)
  end

  def self.fallback_search(query, limit = 10)
    search(query).limit(limit)
  end

  def generate_embeddings
    return if content.blank? && title.blank?
    
    embedding_service = EmbeddingService.new
    
    # Generate embeddings for both content and title
    content_emb = embedding_service.generate_embedding(content) if content.present?
    title_emb = embedding_service.generate_embedding(title) if title.present?
    
    # Convert arrays to proper format for pgvector
    updates = {}
    updates[:content_embedding] = format_embedding_for_db(content_emb) if content_emb
    updates[:title_embedding] = format_embedding_for_db(title_emb) if title_emb
    
    if updates.any?
      # Use raw SQL to properly insert vector data
      updates.each do |column, embedding|
        ActiveRecord::Base.connection.execute(
          "UPDATE knowledge_items SET #{column} = '#{embedding}' WHERE id = #{id}"
        )
      end
    end
  end

  private

  def should_generate_embeddings?
    (content_changed? || title_changed?) && (content.present? || title.present?)
  end

  def generate_embeddings_async
    # Use background job for embedding generation
    GenerateEmbeddingsJob.perform_later('KnowledgeItem', id)
  end

  def format_embedding_for_db(embedding)
    return nil unless embedding.is_a?(Array)
    "[#{embedding.join(',')}]"
  end
end
