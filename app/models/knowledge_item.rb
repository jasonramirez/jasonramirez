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
    
    embedding_service = OllamaEmbeddingService.new
    query_embedding = embedding_service.generate_embedding(query)
    
    return fallback_search(query, limit) if query_embedding.nil?
    
    # Get all items with embeddings and calculate similarity in Ruby
    items = with_embeddings.limit(limit * 3)
    
    # Calculate similarity for each item
    items_with_similarity = items.map do |item|
      stored_embedding = parse_embedding_from_text(item.content_embedding)
      next nil unless stored_embedding
      
      similarity = calculate_cosine_similarity(query_embedding, stored_embedding)
      
      # Apply feedback-based adjustment
      adjusted_similarity = similarity
      if item.total_feedback_count && item.total_feedback_count >= 3
        if item.feedback_score && item.feedback_score >= 0.7
          adjusted_similarity *= 0.8  # Boost good content
        elsif item.feedback_score && item.feedback_score <= 0.3
          adjusted_similarity *= 1.2  # Penalize poor content
        end
      end
      
      item.define_singleton_method(:similarity_score) { similarity }
      item.define_singleton_method(:adjusted_similarity_score) { adjusted_similarity }
      
      [item, adjusted_similarity]
    end.compact.sort_by { |_, adjusted_similarity| -adjusted_similarity }.first(limit)
    
    items_with_similarity.map(&:first)
  end

  def self.fallback_search(query, limit = 10)
    search(query).limit(limit)
  end

  def generate_embeddings
    return if content.blank?
    
    embedding_service = OllamaEmbeddingService.new
    
    # Generate embedding for content only
    content_emb = embedding_service.generate_embedding(content) if content.present?
    
    if content_emb
      # Use raw SQL to properly insert vector data
      formatted_embedding = format_embedding_for_db(content_emb)
      ActiveRecord::Base.connection.execute(
        "UPDATE knowledge_items SET content_embedding = '#{formatted_embedding}' WHERE id = #{id}"
      )
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
