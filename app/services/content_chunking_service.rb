class ContentChunkingService
  MAX_CHUNK_SIZE = 1000  # characters
  MIN_CHUNK_SIZE = 200   # characters
  OVERLAP_SIZE = 100     # characters for context continuity

  def initialize
    @embedding_service = OllamaEmbeddingService.new
  end

  def chunk_knowledge_item(knowledge_item)
    return [] if knowledge_item.content.blank?

    chunks = []
    
    # Try semantic chunking first (by paragraphs/sections)
    semantic_chunks = chunk_by_semantics(knowledge_item.content)
    
    if semantic_chunks.any?
      semantic_chunks.each_with_index do |chunk_content, index|
        chunks << create_chunk(knowledge_item, chunk_content, index, 'semantic')
      end
    else
      # Fallback to size-based chunking
      size_chunks = chunk_by_size(knowledge_item.content)
      size_chunks.each_with_index do |chunk_content, index|
        chunks << create_chunk(knowledge_item, chunk_content, index, 'size')
      end
    end

    chunks
  end

  def chunk_all_knowledge_items
    puts "🧩 Starting intelligent content chunking..."
    
    # Clear existing chunks
    KnowledgeChunk.delete_all
    
    total_items = KnowledgeItem.count
    processed = 0
    total_chunks = 0

    KnowledgeItem.find_each do |item|
      print "\r🧩 Processing #{processed + 1}/#{total_items}: #{item.title.truncate(50)}"
      
      begin
        chunks = chunk_knowledge_item(item)
        
        chunks.each do |chunk_data|
          chunk = KnowledgeChunk.create!(chunk_data)
          chunk.generate_embeddings if chunk.persisted?
          total_chunks += 1
        end
        
        processed += 1
      rescue => e
        puts "\n❌ Error processing #{item.title}: #{e.message}"
      end
      
      # Rate limiting
      sleep(0.1) if processed % 5 == 0
    end

    puts "\n✅ Created #{total_chunks} chunks from #{processed} knowledge items"
    
    # Add indexes for chunks
    add_chunk_indexes
  end

  private

  def chunk_by_semantics(content)
    # Clean content first
    clean_content = ActionView::Base.full_sanitizer.sanitize(content)
    
    # Split by double newlines (paragraphs) or headers
    sections = clean_content.split(/\n\s*\n|\n#+\s+/).reject(&:blank?)
    
    chunks = []
    current_chunk = ""
    
    sections.each do |section|
      section = section.strip
      next if section.blank?
      
      # If adding this section would exceed max size, save current chunk
      if (current_chunk.length + section.length) > MAX_CHUNK_SIZE && current_chunk.length >= MIN_CHUNK_SIZE
        chunks << current_chunk.strip
        current_chunk = get_overlap(current_chunk) + section
      else
        current_chunk += (current_chunk.blank? ? "" : "\n\n") + section
      end
    end
    
    # Add the last chunk if it's substantial
    chunks << current_chunk.strip if current_chunk.length >= MIN_CHUNK_SIZE
    
    # If we only got one chunk and it's too large, fall back to size-based chunking
    if chunks.length == 1 && chunks.first.length > MAX_CHUNK_SIZE * 1.5
      return []
    end
    
    chunks
  end

  def chunk_by_size(content)
    clean_content = ActionView::Base.full_sanitizer.sanitize(content)
    chunks = []
    
    start_pos = 0
    
    while start_pos < clean_content.length
      end_pos = start_pos + MAX_CHUNK_SIZE
      
      # If this isn't the last chunk, try to break at a sentence or word boundary
      if end_pos < clean_content.length
        # Look for sentence endings within the last 200 characters
        sentence_break = clean_content.rindex(/[.!?]\s+/, end_pos)
        if sentence_break && sentence_break > (end_pos - 200)
          end_pos = sentence_break + 1
        else
          # Fall back to word boundary
          word_break = clean_content.rindex(/\s/, end_pos)
          end_pos = word_break if word_break && word_break > (end_pos - 100)
        end
      end
      
      chunk = clean_content[start_pos...end_pos].strip
      chunks << chunk if chunk.length >= MIN_CHUNK_SIZE
      
      # Move start position with overlap for context
      start_pos = [end_pos - OVERLAP_SIZE, end_pos].min
    end
    
    chunks
  end

  def get_overlap(text)
    # Get the last OVERLAP_SIZE characters, trying to break at word boundary
    return "" if text.length <= OVERLAP_SIZE
    
    overlap_start = text.length - OVERLAP_SIZE
    word_break = text.rindex(/\s/, text.length - 1)
    
    if word_break && word_break > overlap_start
      text[word_break..-1].strip + " "
    else
      text[-OVERLAP_SIZE..-1].strip + " "
    end
  end

  def create_chunk(knowledge_item, content, index, chunk_type)
    {
      knowledge_item_id: knowledge_item.id,
      content: content,
      chunk_index: index,
      chunk_type: chunk_type,
      title: "#{knowledge_item.title} (Part #{index + 1})",
      category: knowledge_item.category,
      tags: knowledge_item.tags,
      confidence_score: knowledge_item.confidence_score,
      source: knowledge_item.source,
      last_updated: knowledge_item.last_updated || Time.current
    }
  end

  def add_chunk_indexes
    puts "📊 Adding vector indexes for chunks..."
    begin
      ActiveRecord::Base.connection.execute(
        "CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_knowledge_chunks_content_embedding 
         ON knowledge_chunks USING hnsw (content_embedding vector_cosine_ops)"
      )
      puts "✅ Chunk vector indexes created successfully"
    rescue => e
      puts "⚠️  Chunk index creation warning: #{e.message}"
    end
  end
end
