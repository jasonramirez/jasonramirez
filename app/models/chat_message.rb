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
    
    embedding_service = EmbeddingService.new
    embedding = embedding_service.generate_embedding(content)
    
    if embedding
      ActiveRecord::Base.connection.execute(
        "UPDATE chat_messages SET content_embedding = '#{format_embedding_for_db(embedding)}' WHERE id = #{id}"
      )
    end
  end

  # Find similar messages in conversation history
  def self.find_similar_messages(query, user_id, limit: 5)
    return [] if query.blank?
    
    embedding_service = EmbeddingService.new
    query_embedding = embedding_service.generate_embedding(query)
    
    return [] if query_embedding.nil?
    
    formatted_embedding = "[#{query_embedding.join(',')}]"
    
    # Use raw SQL to avoid ActiveRecord conflicts with AS clauses
    sql = <<~SQL
      SELECT chat_messages.*, 
             content_embedding <=> '#{formatted_embedding}' AS similarity_score
      FROM chat_messages 
      WHERE chat_user_id = #{user_id.to_i}
        AND content_embedding IS NOT NULL
      ORDER BY content_embedding <=> '#{formatted_embedding}'
      LIMIT #{limit.to_i}
    SQL
    
    # Execute raw SQL and map to ActiveRecord objects
    results = connection.exec_query(sql)
    results.map do |row|
      # Remove similarity_score from attributes since it's not a column
      similarity = row.delete('similarity_score').to_f
      
      # Create a proper ActiveRecord object
      message = new(row)
      message.instance_variable_set(:@new_record, false)
      
      # Add similarity_score as a method
      message.define_singleton_method(:similarity_score) { similarity }
      
      message
    end
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
end
