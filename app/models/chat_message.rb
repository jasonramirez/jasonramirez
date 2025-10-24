require 'timeout'

class ChatMessage < ActiveRecord::Base
  belongs_to :chat_user
  
  validates :content, presence: true
  validates :message_type, presence: true, inclusion: { in: %w[question answer] }
  
  scope :for_user, ->(user_id) { where(chat_user_id: user_id) }
  scope :ordered, -> { order(created_at: :asc) }
  scope :recent, ->(limit = 10) { order(created_at: :desc).limit(limit) }
  scope :questions, -> { where(message_type: 'question') }
  scope :answers, -> { where(message_type: 'answer') }
  scope :with_embeddings, -> { where.not(content_embedding: nil) }

  after_save :generate_embedding_sync_then_async, if: :should_generate_embedding?

  def generate_embedding
    return if content.blank? || new_record?
    
    embedding_service = OllamaEmbeddingService.new
    embedding = embedding_service.generate_embedding(content)
    
    if embedding
      update_column(:content_embedding, format_embedding_for_db(embedding))
    end
  end

  # Find similar messages in conversation history
  def self.find_similar_messages(query, user_id, limit: 5)
    return [] if query.blank?
    
    embedding_service = OllamaEmbeddingService.new
    query_embedding = embedding_service.generate_embedding(query)
    
    return [] if query_embedding.nil?
    
    # Get all messages with embeddings for the user
    messages = where(chat_user_id: user_id)
                .where.not(content_embedding: nil)
                .limit(limit * 3) # Get more than needed for similarity calculation
    
    # Calculate similarity scores and sort
    messages_with_similarity = messages.map do |message|
      stored_embedding = parse_embedding_from_text(message.content_embedding)
      next nil unless stored_embedding
      
      similarity = calculate_cosine_similarity(query_embedding, stored_embedding)
      message.define_singleton_method(:similarity_score) { similarity }
      [message, similarity]
    end.compact.sort_by { |_, similarity| -similarity }.first(limit)
    
    messages_with_similarity.map(&:first)
  end

  private

  def should_generate_embedding?
    return false unless content.present?
    
    if respond_to?(:content_embedding)
      content_embedding.nil? || content_embedding.blank?
    else
      # If content_embedding attribute doesn't exist, we should generate embedding
      true
    end
  end

  def generate_embedding_sync_then_async
    # Try to generate embedding immediately for conversation continuity
    begin
      # Quick timeout to avoid blocking the response
      Timeout::timeout(3) do
        generate_embedding
      end
    rescue Timeout::Error, StandardError => e
      Rails.logger.warn "Immediate embedding generation failed, falling back to async: #{e.message}"
      generate_embedding_async
    end
  end

  def generate_embedding_async
    # Use background job for embedding generation
    GenerateEmbeddingsJob.perform_later('ChatMessage', id)
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
