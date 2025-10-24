namespace :ollama do
  desc "Test Ollama integration"
  task test: :environment do
    puts "Testing Ollama integration..."
    
    begin
      ollama_service = OllamaService.new
      
      # Test health check
      puts "1. Testing health check..."
      if ollama_service.health_check
        puts "   ✓ Ollama is running and accessible"
      else
        puts "   ✗ Ollama health check failed"
        exit 1
      end
      
      # Test chat completion
      puts "2. Testing chat completion..."
      messages = [
        { role: "user", content: "Hello, how are you?" }
      ]
      
      response = ollama_service.chat(messages, { temperature: 0.7, max_tokens: 50 })
      if response
        puts "   ✓ Chat completion working"
        puts "   Response: #{response[0..100]}..."
      else
        puts "   ✗ Chat completion failed"
      end
      
      # Test embedding generation
      puts "3. Testing embedding generation..."
      embedding = ollama_service.generate_embedding("This is a test sentence for embedding generation.")
      if embedding && embedding.is_a?(Array) && embedding.length > 0
        puts "   ✓ Embedding generation working"
        puts "   Embedding dimension: #{embedding.length}"
      else
        puts "   ✗ Embedding generation failed"
      end
      
      puts "\nOllama integration test completed!"
      
    rescue => e
      puts "Error testing Ollama integration: #{e.message}"
      puts "Make sure Ollama is running with: ollama serve"
      puts "And that you have a model installed: ollama pull llama3.2"
      exit 1
    end
  end
  
  desc "Test conversation service with Ollama"
  task test_conversation: :environment do
    puts "Testing Ollama conversation service..."
    
    begin
      conversation_service = OllamaConversationService.new
      
      # Test with a simple question
      result = conversation_service.respond_to_question("What is your name?", nil)
      
      if result && result.is_a?(Hash) && result[:text]
        puts "✓ Conversation service working"
        puts "Response: #{result[:text]}"
        puts "Knowledge base influence: #{result[:knowledge_base_influence]}"
      else
        puts "✗ Conversation service failed"
        puts "Result: #{result.inspect}"
      end
      
    rescue => e
      puts "Error testing conversation service: #{e.message}"
      exit 1
    end
  end
end
