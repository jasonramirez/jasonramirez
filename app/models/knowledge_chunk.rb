class KnowledgeChunk < ActiveRecord::Base
  belongs_to :knowledge_item
  
  validates :content, presence: true
  validates :chunk_index, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :chunk_type, presence: true, inclusion: { in: %w[semantic size] }
  validates :confidence_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: true

  scope :by_category, ->(category) { where(category: category) }
  scope :by_type, ->(type) { where(chunk_type: type) }
  scope :high_confidence, -> { where('confidence_score >= ?', 0.8) }
  scope :with_embeddings, -> { where.not(content_embedding: nil) }
  scope :ordered, -> { order(:knowledge_item_id, :chunk_index) }

  after_save :generate_embeddings_async, if: :should_generate_embeddings?

  # Semantic search using embeddings with feedback-aware ranking
  def self.semantic_search(query, limit: 20)
    return [] if query.blank?
    
    embedding_service = EmbeddingService.new
    query_embedding = embedding_service.generate_embedding(query)
    
    return [] if query_embedding.nil?
    
    # Get all chunks with embeddings
    chunks = joins(:knowledge_item)
              .where.not(content_embedding: nil)
              .limit(limit * 10) # Get more chunks to ensure we find the best matches
    
    # Calculate similarity scores and sort
    chunks_with_similarity = chunks.map do |chunk|
      stored_embedding = self.parse_embedding_from_text(chunk.content_embedding)
      next nil unless stored_embedding
      
      similarity = self.calculate_cosine_similarity(query_embedding, stored_embedding)
      
      # Apply feedback-based adjustment
      adjusted_similarity = similarity
      if chunk.knowledge_item.total_feedback_count >= 3
        if chunk.knowledge_item.feedback_score >= 0.7
          adjusted_similarity *= 0.8  # Boost good content
        elsif chunk.knowledge_item.feedback_score <= 0.3
          adjusted_similarity *= 1.2  # Penalize poor content
        end
      end
      
      chunk.define_singleton_method(:similarity_score) { similarity }
      chunk.define_singleton_method(:adjusted_similarity_score) { adjusted_similarity }
      
      [chunk, adjusted_similarity]
    end.compact.sort_by { |_, adjusted_similarity| -adjusted_similarity }.first(limit)
    
    chunks_with_similarity.map(&:first)
  end

  def generate_embeddings
    return if content.blank?
    
    embedding_service = EmbeddingService.new
    content_emb = embedding_service.generate_embedding(content)
    
    if content_emb
      ActiveRecord::Base.connection.execute(
        "UPDATE knowledge_chunks SET content_embedding = '#{format_embedding_for_db(content_emb)}' WHERE id = #{id}"
      )
    end
  end

  def tags_array
    tags.present? ? tags.split(',').map(&:strip) : []
  end

  def tags_array=(tags_array)
    self.tags = tags_array.reject(&:blank?).join(', ')
  end

  private

  def should_generate_embeddings?
    content.present? && content_embedding.blank?
  end

  def generate_embeddings_async
    # Use background job for embedding generation
    GenerateEmbeddingsJob.perform_later('KnowledgeChunk', id)
  end

  def format_embedding_for_db(embedding)
    return nil unless embedding.is_a?(Array)
    "[#{embedding.join(',')}]"
  end

  def self.parse_embedding_from_text(embedding_text)
    return nil if embedding_text.blank?

    # Parse the embedding from text format "[1.0,2.0,3.0]"
    embedding_text.gsub(/[\[\]]/, '').split(',').map(&:to_f)
  rescue
    nil
  end

  def self.calculate_cosine_similarity(embedding1, embedding2)
    return 0.0 if embedding1.nil? || embedding2.nil?
    return 0.0 if embedding1.length != embedding2.length

    # Calculate dot product
    dot_product = embedding1.zip(embedding2).map { |a, b| a * b }.sum

    # Calculate magnitudes
    magnitude1 = Math.sqrt(embedding1.map { |x| x * x }.sum)
    magnitude2 = Math.sqrt(embedding2.map { |x| x * x }.sum)

    return 0.0 if magnitude1 == 0 || magnitude2 == 0

    # Return cosine similarity
    dot_product / (magnitude1 * magnitude2)
  end
end
