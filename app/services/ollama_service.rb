require 'net/http'
require 'json'
require 'uri'

class OllamaService
  def initialize
    @base_url = ENV['OLLAMA_BASE_URL'] || 'http://localhost:11434'
    @model = ENV['OLLAMA_MODEL'] || 'llama3.2'
    @timeout = ENV['OLLAMA_TIMEOUT']&.to_i || 30
  end

  def chat(messages, options = {})
    return nil if messages.blank?

    begin
      response = make_request('/api/chat', {
        model: @model,
        messages: messages,
        stream: false,
        options: {
          temperature: options[:temperature] || 0.7,
          max_tokens: options[:max_tokens] || 150,
          top_p: options[:top_p] || 0.9
        }
      })

      return nil unless response.is_a?(Hash)
      response.dig('message', 'content')
    rescue => e
      Rails.logger.error "Ollama chat error: #{e.message}"
      nil
    end
  end

  def generate_embedding(text)
    return nil if text.blank?

    begin
      response = make_request('/api/embeddings', {
        model: @model,
        prompt: clean_text_for_embedding(text)
      })

      return nil unless response.is_a?(Hash)
      response['embedding']
    rescue => e
      Rails.logger.error "Ollama embedding error: #{e.message}"
      nil
    end
  end

  def generate_embeddings_batch(texts)
    return [] if texts.empty?

    begin
      response = make_request('/api/embeddings', {
        model: @model,
        prompt: texts.map { |text| clean_text_for_embedding(text) }
      })

      return [] unless response.is_a?(Hash)
      response['embeddings'] || []
    rescue => e
      Rails.logger.error "Ollama batch embedding error: #{e.message}"
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

  def health_check
    begin
      response = make_get_request('/api/tags')
      response.is_a?(Hash) && response.key?('models')
    rescue => e
      Rails.logger.error "Ollama health check failed: #{e.message}"
      false
    end
  end

  private

  def make_get_request(endpoint)
    uri = URI("#{@base_url}#{endpoint}")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = @timeout
    http.open_timeout = @timeout
    
    request = Net::HTTP::Get.new(uri)
    request['Content-Type'] = 'application/json'
    
    response = http.request(request)
    
    case response.code.to_i
    when 200
      JSON.parse(response.body)
    else
      Rails.logger.error "Ollama GET API error: #{response.code} - #{response.body}"
      nil
    end
  rescue Net::ReadTimeout, Net::OpenTimeout
    Rails.logger.error "Ollama GET request timeout"
    nil
  rescue => e
    Rails.logger.error "Ollama GET request error: #{e.message}"
    nil
  end

  def make_request(endpoint, payload)
    uri = URI("#{@base_url}#{endpoint}")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = @timeout
    http.open_timeout = @timeout
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = payload.to_json
    
    response = http.request(request)
    
    case response.code.to_i
    when 200
      JSON.parse(response.body)
    when 404
      Rails.logger.error "Ollama model not found: #{@model}"
      nil
    when 500
      Rails.logger.error "Ollama server error: #{response.body}"
      nil
    else
      Rails.logger.error "Ollama API error: #{response.code} - #{response.body}"
      nil
    end
  rescue Net::ReadTimeout, Net::OpenTimeout
    Rails.logger.error "Ollama request timeout"
    nil
  rescue => e
    Rails.logger.error "Ollama request error: #{e.message}"
    nil
  end

  def clean_text_for_embedding(text)
    return "" if text.blank?
    
    # Remove HTML tags, normalize whitespace, and truncate
    cleaned = ActionView::Base.full_sanitizer.sanitize(text)
    cleaned = cleaned.gsub(/\s+/, ' ').strip
    
    # Truncate to approximately 8000 tokens (rough estimate: 4 chars per token)
    cleaned.truncate(32000)
  end
end
