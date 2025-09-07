class KnowledgeItem < ActiveRecord::Base
  validates :title, presence: true
  validates :content, presence: true
  validates :category, presence: true
  validates :confidence_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: true

  scope :by_category, ->(category) { where(category: category) }
  scope :high_confidence, -> { where('confidence_score >= ?', 0.8) }
  scope :recent, -> { order(last_updated: :desc) }
  scope :with_embeddings, -> { where.not(content_embedding: nil) }
  scope :by_feedback_score, -> { order(feedback_score: :desc) }
  scope :well_rated, -> { where('feedback_score >= ? AND total_feedback_count >= ?', 0.7, 5) }
  scope :poorly_rated, -> { where('feedback_score <= ? AND total_feedback_count >= ?', 0.3, 5) }

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

  # Feedback scoring methods
  def update_feedback_score(is_positive, weight = 1.0)
    ActiveRecord::Base.transaction do
      increment_feedback_counts(is_positive, weight)
      recalculate_feedback_score
      touch(:last_feedback_at)
    end
  end

  def feedback_satisfaction_rate
    return 0.0 if total_feedback_count == 0
    (positive_feedback_count.to_f / total_feedback_count * 100).round(1)
  end

  def has_sufficient_feedback?(min_count = 5)
    total_feedback_count >= min_count
  end

  def feedback_quality_indicator
    return 'unknown' if total_feedback_count < 3
    
    case feedback_score
    when 0.7..1.0
      'excellent'
    when 0.6...0.7
      'good'
    when 0.4...0.6
      'average'
    when 0.2...0.4
      'poor'
    else
      'very_poor'
    end
  end

  # Semantic search using embeddings with feedback-aware ranking
  def self.semantic_search(query, limit: 10)
    return [] if query.blank?
    
    embedding_service = EmbeddingService.new
    query_embedding = embedding_service.generate_embedding(query)
    
    return fallback_search(query, limit) if query_embedding.nil?
    
    # Format embedding for database query
    formatted_embedding = "[#{query_embedding.join(',')}]"
    
    # Use pgvector for cosine similarity search with Arel.sql for vector operations
    # Incorporate feedback scores into ranking: boost items with good feedback
    with_embeddings
      .select(Arel.sql("*, 
                       content_embedding <=> '#{formatted_embedding}' AS similarity_score,
                       (content_embedding <=> '#{formatted_embedding}') * 
                       CASE 
                         WHEN total_feedback_count >= 3 THEN 
                           CASE 
                             WHEN feedback_score >= 0.7 THEN 0.8  -- Boost good content (lower distance = better)
                             WHEN feedback_score <= 0.3 THEN 1.2  -- Penalize poor content (higher distance = worse)
                             ELSE 1.0  -- Neutral
                           END
                         ELSE 1.0  -- No adjustment for items with insufficient feedback
                       END AS adjusted_similarity_score"))
      .order(Arel.sql("adjusted_similarity_score"))
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

  def increment_feedback_counts(is_positive, weight)
    # Handle fractional weights properly
    new_total = (total_feedback_count || 0) + weight
    new_positive = (positive_feedback_count || 0) + (is_positive ? weight : 0)
    
    update_columns(
      total_feedback_count: new_total,
      positive_feedback_count: new_positive
    )
  end

  def recalculate_feedback_score
    return if total_feedback_count == 0
    
    # Calculate raw satisfaction rate
    raw_score = positive_feedback_count.to_f / total_feedback_count
    
    # Apply confidence multiplier based on sample size (more feedback = more reliable)
    confidence_multiplier = [total_feedback_count / 20.0, 1.0].min
    
    # Blend with baseline (0.5) for items with little feedback
    blended_score = (raw_score * confidence_multiplier) + (0.5 * (1 - confidence_multiplier))
    
    update_column(:feedback_score, blended_score.round(2))
  end

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
