namespace :embeddings do
  desc "Generate embeddings for all knowledge items"
  task generate_all: :environment do
    puts "🔮 Generating embeddings for all knowledge items..."
    
    total_items = KnowledgeItem.count
    processed = 0
    
    KnowledgeItem.find_each do |item|
      print "\r🔮 Processing #{processed + 1}/#{total_items}: #{item.title.truncate(50)}"
      
      begin
        item.generate_embeddings
        processed += 1
      rescue => e
        puts "\n❌ Error processing #{item.title}: #{e.message}"
      end
      
      # Rate limiting to avoid hitting OpenAI API limits
      sleep(0.1) if processed % 10 == 0
    end
    
    puts "\n✅ Generated embeddings for #{processed}/#{total_items} knowledge items"
    
    # Add vector indexes after data is populated
    puts "📊 Adding vector indexes..."
    begin
      ActiveRecord::Base.connection.execute(
        "CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_knowledge_items_content_embedding 
         ON knowledge_items USING hnsw (content_embedding vector_cosine_ops)"
      )
      ActiveRecord::Base.connection.execute(
        "CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_knowledge_items_title_embedding 
         ON knowledge_items USING hnsw (title_embedding vector_cosine_ops)"
      )
      puts "✅ Vector indexes created successfully"
    rescue => e
      puts "⚠️  Index creation warning: #{e.message}"
    end
  end

  desc "Test semantic search"
  task :test_search, [:query] => :environment do |t, args|
    query = args[:query] || "design process"
    
    puts "🔍 Testing semantic search for: '#{query}'"
    puts "=" * 50
    
    results = KnowledgeItem.semantic_search(query, limit: 5)
    
    if results.empty?
      puts "No results found"
    else
      results.each_with_index do |item, index|
        similarity = item.respond_to?(:similarity_score) ? item.similarity_score.round(3) : "N/A"
        puts "#{index + 1}. #{item.title} (#{item.category})"
        puts "   Similarity: #{similarity}"
        puts "   Content: #{item.content.truncate(100)}"
        puts
      end
    end
  end

  desc "Generate embeddings for chat messages"
  task generate_chat_embeddings: :environment do
    puts "💬 Generating embeddings for chat messages..."
    
    embedding_service = OllamaEmbeddingService.new
    total_messages = ChatMessage.where(content_embedding: nil).count
    processed = 0
    
    ChatMessage.where(content_embedding: nil).find_each do |message|
      print "\r💬 Processing #{processed + 1}/#{total_messages}"
      
      begin
        embedding = embedding_service.generate_embedding(message.content)
        if embedding
          formatted_embedding = "[#{embedding.join(',')}]"
          ActiveRecord::Base.connection.execute(
            "UPDATE chat_messages SET content_embedding = '#{formatted_embedding}' WHERE id = #{message.id}"
          )
        end
        processed += 1
      rescue => e
        puts "\n❌ Error processing message #{message.id}: #{e.message}"
      end
      
      sleep(0.1) if processed % 10 == 0
    end
    
    puts "\n✅ Generated embeddings for #{processed}/#{total_messages} chat messages"
  end

  desc "Generate content chunks from knowledge items"
  task generate_chunks: :environment do
    chunking_service = ContentChunkingService.new
    chunking_service.chunk_all_knowledge_items
  end

  desc "Test chunk-based semantic search"
  task :test_chunk_search, [:query] => :environment do |t, args|
    query = args[:query] || "design process"
    
    puts "🧩 Testing chunk-based semantic search for: '#{query}'"
    puts "=" * 60
    
    results = KnowledgeChunk.semantic_search(query, limit: 8)
    
    if results.empty?
      puts "No chunk results found"
    else
      results.each_with_index do |chunk, index|
        similarity = chunk.respond_to?(:similarity_score) ? chunk.similarity_score.round(3) : "N/A"
        puts "#{index + 1}. #{chunk.title} (#{chunk.chunk_type} chunk)"
        puts "   Similarity: #{similarity} | Category: #{chunk.category}"
        puts "   Content: #{chunk.content.truncate(120)}"
        puts
      end
    end
  end
end
