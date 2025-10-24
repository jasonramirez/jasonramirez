class OllamaEmbeddingService
  def initialize
    @ollama_service = OllamaService.new
  end

  def generate_embedding(text)
    return nil if text.blank?
    
    # Clean and truncate text for embedding
    cleaned_text = clean_text_for_embedding(text)
    
    begin
      @ollama_service.generate_embedding(cleaned_text)
    rescue => e
      Rails.logger.error "Ollama embedding generation error: #{e.message}"
      nil
    end
  end

  def generate_embeddings_batch(texts)
    return [] if texts.empty?
    
    cleaned_texts = texts.map { |text| clean_text_for_embedding(text) }
    
    begin
      @ollama_service.generate_embeddings_batch(cleaned_texts)
    rescue => e
      Rails.logger.error "Ollama batch embedding generation error: #{e.message}"
      []
    end
  end

  def cosine_similarity(embedding1, embedding2)
    @ollama_service.cosine_similarity(embedding1, embedding2)
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
