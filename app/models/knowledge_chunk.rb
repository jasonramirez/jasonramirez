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

  # Semantic search using embeddings
  def self.semantic_search(query, limit: 20)
    return [] if query.blank?
    
    embedding_service = EmbeddingService.new
    query_embedding = embedding_service.generate_embedding(query)
    
    return [] if query_embedding.nil?
    
    # Format embedding for database query
    formatted_embedding = "[#{query_embedding.join(',')}]"
    
    # Use raw SQL to avoid ActiveRecord conflicts with AS clauses
    sql = <<~SQL
      SELECT knowledge_chunks.*, 
             content_embedding <=> '#{formatted_embedding}' AS similarity_score
      FROM knowledge_chunks 
      WHERE content_embedding IS NOT NULL
      ORDER BY content_embedding <=> '#{formatted_embedding}'
      LIMIT #{limit}
    SQL
    
    # Execute raw SQL and map to ActiveRecord objects
    results = connection.exec_query(sql)
    results.map do |row|
      # Remove similarity_score from attributes since it's not a column
      similarity = row.delete('similarity_score').to_f
      
      # Create a proper ActiveRecord object
      chunk = new(row)
      chunk.instance_variable_set(:@new_record, false)
      
      # Add similarity_score as a method
      chunk.define_singleton_method(:similarity_score) { similarity }
      
      chunk
    end
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
end
