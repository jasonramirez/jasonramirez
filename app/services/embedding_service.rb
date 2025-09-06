class EmbeddingService
  def initialize
    api_key = ENV['OPENAI_API_KEY']
    raise "OpenAI API key not configured" if api_key.blank?
    
    @client = OpenAI::Client.new(access_token: api_key)
  end

  def generate_embedding(text)
    return nil if text.blank?
    
    # Clean and truncate text for embedding (OpenAI has token limits)
    cleaned_text = clean_text_for_embedding(text)
    
    begin
      response = @client.embeddings(
        parameters: {
          model: "text-embedding-3-small",
          input: cleaned_text
        }
      )
      
      return nil unless response.is_a?(Hash)
      response.dig("data", 0, "embedding")
    rescue => e
      Rails.logger.error "Embedding generation error: #{e.message}"
      nil
    end
  end

  def generate_embeddings_batch(texts)
    return [] if texts.empty?
    
    cleaned_texts = texts.map { |text| clean_text_for_embedding(text) }
    
    begin
      response = @client.embeddings(
        parameters: {
          model: "text-embedding-3-small",
          input: cleaned_texts
        }
      )
      
      response["data"].map { |item| item["embedding"] }
    rescue => e
      Rails.logger.error "Batch embedding generation error: #{e.message}"
      []
    end
  end

  def cosine_similarity(embedding1, embedding2)
    return 0.0 if embedding1.nil? || embedding2.nil?
    
    # Convert to arrays if they're not already
    vec1 = embedding1.is_a?(Array) ? embedding1 : embedding1.to_a
    vec2 = embedding2.is_a?(Array) ? embedding2 : embedding2.to_a
    
    return 0.0 if vec1.length != vec2.length
    
    dot_product = vec1.zip(vec2).sum { |a, b| a * b }
    magnitude1 = Math.sqrt(vec1.sum { |a| a * a })
    magnitude2 = Math.sqrt(vec2.sum { |a| a * a })
    
    return 0.0 if magnitude1 == 0 || magnitude2 == 0
    
    dot_product / (magnitude1 * magnitude2)
  end

  private

  def clean_text_for_embedding(text)
    return "" if text.blank?
    
    # Remove HTML tags, normalize whitespace, and truncate
    cleaned = ActionView::Base.full_sanitizer.sanitize(text)
    cleaned = cleaned.gsub(/\s+/, ' ').strip
    
    # Truncate to approximately 8000 tokens (rough estimate: 4 chars per token)
    cleaned.truncate(32000)
  end
end
