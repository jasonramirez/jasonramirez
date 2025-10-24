require 'ostruct'

class OllamaConversationService
  STOP_WORDS = %w[
    a an and are as at be by for from has he in is it its of on that the they to was will with
    your you what where when why how this that these those i me my myself we our ours ourselves
    is are was were been being have has had do does did will would could should may might must
    can shall ought need dare
  ].freeze

  def initialize
    @ollama_service = OllamaService.new
    @conversation_history = []
  end

  def respond_to_question(question, user_id = nil)
    begin
      Rails.logger.info "OllamaConversationService: Starting to process question: #{question}"
      
      # Get conversation context if user_id is provided
      conversation_context = user_id ? get_conversation_context(question, user_id) : nil
      
      Rails.logger.info "OllamaConversationService: Searching knowledge base"
      relevant_items = search_knowledge_base(question)
      
      # First check if we have relevant items before calculating influence
      if relevant_items.empty?
        return build_response(
          "I don't have specific information about that in my knowledge base yet. I'd be happy to help you add relevant content, or you can ask me about topics I do have experience with.",
          empty_kb_influence
        )
      end
      
      Rails.logger.info "OllamaConversationService: Building context with #{relevant_items.count} items"
      context = build_context(relevant_items, conversation_context)
      
      Rails.logger.info "OllamaConversationService: Generating LLM response"
      response = generate_llm_response(question, context, conversation_context)
      
      Rails.logger.info "OllamaConversationService: Storing conversation"
      store_conversation(question, response, user_id)
      
      # Calculate influence after generating response
      kb_influence = calculate_knowledge_base_influence(relevant_items, response, question)
      
      build_response(response, kb_influence)
    rescue RuntimeError => e
      # Handle configuration errors (like missing API key)
      Rails.logger.error "Configuration error in OllamaConversationService: #{e.message}"
      build_response(
        "I'm sorry, there's a configuration issue. Please contact support.",
        empty_kb_influence
      )
    rescue => e
      Rails.logger.error "Error in OllamaConversationService#respond_to_question: #{e.class.name}: #{e.message}"
      Rails.logger.error "Question: #{question}"
      Rails.logger.error "User ID: #{user_id}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(10).join("\n")}"
      
      # Check if it's a specific type of error we can handle
      error_message = case e
      when Net::ReadTimeout, Net::OpenTimeout
        "I'm experiencing connectivity issues with my AI service. Please try again in a moment."
      when ActiveRecord::StatementInvalid
        "I'm having trouble accessing my knowledge base. Please try again."
      else
        "I'm sorry, I encountered an error processing your question. Please try again."
      end
      
      build_response(error_message, empty_kb_influence)
    end
  end

  private

  def process_question_words(question)
    question.downcase
      .gsub(/[^\w\s]/, ' ') # Remove punctuation and replace with spaces
      .split(/\s+/)
      .reject(&:blank?)
      .reject { |word| STOP_WORDS.include?(word) }
      .reject { |word| word.length < 3 }
  end

  def build_response(text, kb_influence)
    # Add inline links to framework mentions if frameworks are available
    linked_text = if kb_influence[:frameworks_available] && kb_influence[:sources]
      add_inline_framework_links(text, kb_influence[:sources])
    else
      text
    end

    {
      text: linked_text,
      audio_path: nil,
      knowledge_base_influence: kb_influence
    }
  end

  def empty_kb_influence
    {
      has_knowledge_base_content: false,
      confidence_score: 0,
      sources_count: 0,
      influence_level: "none",
      raw_confidence: 0,
      avg_relevance: 0,
      sources: []
    }
  end

  def search_knowledge_base(question)
    Rails.logger.info "Search Debug:"
    Rails.logger.info "  Question: #{question}"
    
    # Try chunk-based semantic search first for more precise results
    chunk_results = KnowledgeChunk.semantic_search(question, limit: 15)
    
    if chunk_results.any? && chunk_results.first.respond_to?(:similarity_score)
      Rails.logger.info "  Chunk search results: #{chunk_results.count}"
      
      # Filter chunks by similarity threshold
      good_chunks = chunk_results.select do |chunk|
        similarity = chunk.similarity_score.to_f
        similarity > 0.3  # More lenient threshold for chunks
      end
      
      Rails.logger.info "  High-quality chunk results: #{good_chunks.count}"
      
      # Convert chunks to a format compatible with existing code
      if good_chunks.any?
        chunk_items = good_chunks.map { |chunk| convert_chunk_to_item_format(chunk) }
        return prioritize_frameworks(chunk_items, question)
      end
    end
    
    # Search additional knowledge (private knowledge for AI)
    additional_knowledge_results = AdditionalKnowledge.search_by_similarity(question, limit: 4)
    Rails.logger.info "  Additional knowledge results: #{additional_knowledge_results.count}"
    
    # Fallback to full knowledge item search
    Rails.logger.info "  Falling back to full item search"
    semantic_results = KnowledgeItem.semantic_search(question, limit: 6)
    
    if semantic_results.any? && semantic_results.first.respond_to?(:similarity_score)
      Rails.logger.info "  Full item semantic search results: #{semantic_results.count}"
      good_results = semantic_results.select do |item|
        similarity = item.similarity_score.to_f
        similarity < 0.5
      end
      
      Rails.logger.info "  High-quality full item results: #{good_results.count}"
      
      # Combine additional knowledge with public knowledge
      combined_results = good_results + convert_additional_knowledge_to_item_format(additional_knowledge_results)
      return prioritize_frameworks(combined_results, question) if combined_results.any?
    end
    
    # If no semantic results, try additional knowledge alone
    if additional_knowledge_results.any?
      Rails.logger.info "  Using additional knowledge only"
      return prioritize_frameworks(convert_additional_knowledge_to_item_format(additional_knowledge_results), question)
    end
    
    # Final fallback to progressive keyword search
    Rails.logger.info "  Falling back to keyword search"
    progressive_keyword_search(question)
  end

  def convert_chunk_to_item_format(chunk)
    # Create an object that behaves like a KnowledgeItem for compatibility
    # Fetch parent KnowledgeItem to get feedback scores and other missing fields
    begin
      parent_item = KnowledgeItem.find_by(id: chunk.knowledge_item_id)
      
      ::OpenStruct.new(
        id: "chunk_#{chunk.id}",
        title: chunk.title || parent_item&.title || "Untitled Chunk",
        content: chunk.content || "",
        category: chunk.category || parent_item&.category || "Unknown",
        tags: chunk.tags || parent_item&.tags || "",
        confidence_score: chunk.confidence_score || parent_item&.confidence_score || 0.9,
        similarity_score: chunk.respond_to?(:similarity_score) ? chunk.similarity_score : nil,
        source: chunk.source || parent_item&.source || "",
        chunk_type: chunk.chunk_type || "unknown",
        chunk_index: chunk.chunk_index || 0,
        knowledge_item_id: chunk.knowledge_item_id,
        # Include feedback scores from parent KnowledgeItem
        feedback_score: parent_item&.feedback_score,
        total_feedback_count: parent_item&.total_feedback_count,
        positive_feedback_count: parent_item&.positive_feedback_count,
        last_feedback_at: parent_item&.last_feedback_at
      )
    rescue => e
      Rails.logger.error "Error converting chunk to item format: #{e.message}"
      Rails.logger.error "Chunk: #{chunk.inspect}"
      raise e
    end
  end

  def convert_additional_knowledge_to_item_format(additional_knowledge_items)
    additional_knowledge_items.map do |item|
      ::OpenStruct.new(
        id: "additional_#{item.id}",
        title: item.title,
        content: item.content,
        category: item.respond_to?(:category) ? item.category : "Additional Knowledge",
        tags: "additional-knowledge",
        confidence_score: 0.95, # High confidence for private knowledge
        similarity_score: item.respond_to?(:similarity_score) ? item.similarity_score : nil,
        source: "Additional Knowledge",
        chunk_type: "additional",
        chunk_index: 0,
        knowledge_item_id: nil,
        # No feedback scores for additional knowledge
        feedback_score: nil,
        total_feedback_count: nil,
        positive_feedback_count: nil,
        last_feedback_at: nil
      )
    end
  end

  def progressive_keyword_search(question)
    # Progressive search strategy: start strict, then loosen
    question_words = process_question_words(question)
    return [] if question_words.empty?
    
    Rails.logger.info "  Question words: #{question_words}"
    
    # Tier 1: Strict search - all question words must be present
    strict_results = search_with_all_words(question_words)
    Rails.logger.info "  Tier 1 (strict) results: #{strict_results.count}"
    return prioritize_frameworks(strict_results, question) if strict_results.count >= 2
    
    # Tier 2: Medium search - at least 50% of question words must be present
    medium_results = search_with_percentage_words(question_words, 0.5)
    Rails.logger.info "  Tier 2 (medium) results: #{medium_results.count}"
    return prioritize_frameworks(medium_results, question) if medium_results.count >= 2
    
    # Tier 3: Loose search - any question word present (original behavior)
    loose_results = search_with_any_words(question_words)
    Rails.logger.info "  Tier 3 (loose) results: #{loose_results.count}"
    return prioritize_frameworks(loose_results, question) if loose_results.count >= 1
    
    # Tier 4: Fallback - use original search method
    fallback_results = KnowledgeItem.search(question)
    Rails.logger.info "  Tier 4 (fallback) results: #{fallback_results.count}"
    prioritize_frameworks(fallback_results, question)
  end
  
  def search_with_all_words(question_words)
    conditions = []
    values = {}
    
    question_words.each_with_index do |word, index|
      conditions << "(LOWER(title) LIKE :word#{index} OR LOWER(content) LIKE :word#{index})"
      values["word#{index}".to_sym] = "%#{word}%"
    end
    
    KnowledgeItem.where(conditions.join(' AND '), values)
  end
  
  def search_with_percentage_words(question_words, percentage)
    min_words = [(question_words.length * percentage).ceil, 1].max
    combinations = question_words.combination(min_words).to_a
    
    all_results = []
    combinations.each do |word_combo|
      conditions = []
      values = {}
      
      word_combo.each_with_index do |word, index|
        conditions << "(LOWER(title) LIKE :word#{index} OR LOWER(content) LIKE :word#{index})"
        values["word#{index}".to_sym] = "%#{word}%"
      end
      
      results = KnowledgeItem.where(conditions.join(' AND '), values)
      all_results.concat(results)
    end
    
    # Remove duplicates
    all_results.uniq
  end
  
  def search_with_any_words(question_words)
    conditions = []
    values = {}
    
    question_words.each_with_index do |word, index|
      conditions << "(LOWER(title) LIKE :word#{index} OR LOWER(content) LIKE :word#{index})"
      values["word#{index}".to_sym] = "%#{word}%"
    end
    
    KnowledgeItem.where(conditions.join(' OR '), values)
  end

  def prioritize_frameworks(results, question)
    return results if results.empty?
    
    framework_keywords = ['framework', 'process', 'method', 'approach', 'strategy', 'system']
    question_lower = question.downcase
    
    # Check if the question is asking about frameworks/processes
    asking_about_frameworks = framework_keywords.any? { |keyword| question_lower.include?(keyword) }
    
    # Separate framework items from other items
    framework_items = results.select { |item| item.tags.to_s.downcase.include?('framework') }
    other_items = results.reject { |item| item.tags.to_s.downcase.include?('framework') }
    
    Rails.logger.info "Framework prioritization:"
    Rails.logger.info "  Asking about frameworks: #{asking_about_frameworks}"
    Rails.logger.info "  Framework items found: #{framework_items.count}"
    Rails.logger.info "  Other items found: #{other_items.count}"
    
    # If asking about frameworks or processes, prioritize framework items
    if asking_about_frameworks && framework_items.any?
      # Put framework items first, then other items
      framework_items + other_items
    else
      # Normal ordering, but still include frameworks if they're relevant
      results
    end
  end

  def get_conversation_context(question, user_id)
    # Get recent conversation history
    recent_messages = ChatMessage.for_user(user_id).recent(10)
    
    # Find similar previous questions/topics
    similar_messages = ChatMessage.find_similar_messages(question, user_id, limit: 3)
    
    {
      recent_messages: recent_messages,
      similar_messages: similar_messages,
      has_context: recent_messages.any? || similar_messages.any?
    }
  end

  def build_context(items, conversation_context = nil)
    framework_items = items.select { |item| item.tags.to_s.downcase.include?('framework') }
    
    context_parts = []
    
    # Add conversation context if available
    if conversation_context&.dig(:has_context)
      context_parts << "CONVERSATION CONTEXT:"
      
      if conversation_context[:recent_messages].any?
        context_parts << "Recent conversation:"
        conversation_context[:recent_messages].first(3).each do |msg|
          context_parts << "- #{msg.message_type.capitalize}: #{msg.content.truncate(100)}"
        end
        context_parts << ""
      end
      
      if conversation_context[:similar_messages].any?
        context_parts << "Similar previous topics:"
        conversation_context[:similar_messages].each do |msg|
          similarity = msg.respond_to?(:similarity_score) ? " (#{(1 - msg.similarity_score.to_f).round(2)} similarity)" : ""
          context_parts << "- #{msg.content.truncate(80)}#{similarity}"
        end
        context_parts << ""
      end
    end
    
    # If no items but we have conversation context, return just the conversation context
    if items.empty?
      return context_parts.any? ? context_parts.join("\n") : "No relevant information found in knowledge base."
    end
    
    # Add framework notice if we have frameworks
    if framework_items.any?
      context_parts << "FRAMEWORKS AVAILABLE: #{framework_items.count} framework(s) found that may provide structured approaches to this topic."
      context_parts << ""
    end

    items.map do |item|
      is_framework = item.tags.to_s.downcase.include?('framework')
      
      [
        "Title: #{item.title}#{is_framework ? ' [FRAMEWORK]' : ''}",
        "Category: #{item.category}",
        "Content: #{item.content}",
        "Tags: #{item.tags}" + (is_framework ? " (This is a framework that provides a structured approach)" : ""),
        "Confidence: #{(item.confidence_score * 100).round}%",
        "---"
      ]
    end.flatten.each { |line| context_parts << line }
    
    context_parts.join("\n")
  end

  def generate_llm_response(question, context, conversation_context = nil)
    prompt = build_prompt(question, context, conversation_context)
    
    begin
      messages = [
        { role: "system", content: system_prompt(conversation_context) },
        { role: "user", content: prompt }
      ]
      
      response = @ollama_service.chat(messages, {
        temperature: 0.7,
        max_tokens: 150
      })
      
      response || "I'm sorry, I couldn't generate a response at the moment."
    rescue => e
      Rails.logger.error "Ollama API error: #{e.message}"
      fallback_response(question, context)
    end
  end

  def system_prompt(conversation_context = nil)
    base_prompt = <<~PROMPT
      You are Jason Ramirez, a Product Design Director with extensive experience in product design, leadership, and strategic thinking. You're having a conversation with someone who wants to learn from your expertise.

      CRITICAL: You will ONLY receive questions that have relevant knowledge base content. If you receive a question, it means there IS relevant information available.

      Your responses should be:
      - Conversational and engaging, like you're talking to a colleague
      - Based on the knowledge base context provided
      - Personal and authentic to your voice and experience
      - Helpful and actionable
      - APPROPRIATE LENGTH - match the user's energy and question complexity
      - For simple greetings/personal questions: respond briefly and warmly (1 sentence max)
      - For career/professional questions: provide 2-3 sentences with context
      - For simple personal questions (how are you, what's your name, etc.): keep it casual and brief
      - Focus on the most important point from the context
      - DECLARATIVE - end with statements, not questions

      FRAMEWORK GUIDANCE:
      - When you see "[FRAMEWORK]" in the context, prioritize referencing those structured approaches
      - If frameworks are available, mention them as practical tools the person can use
      - Present frameworks as actionable systems, not just concepts
      - When multiple frameworks are relevant, briefly mention the most applicable one

      IMPORTANT: For non-career questions, don't bring up work or professional topics unless specifically asked.

      Use the knowledge base context to provide accurate, specific information. If the context doesn't fully answer the question, acknowledge what you know and suggest what else might be helpful to explore.

      Always speak in the first person ("I", "my", "me") as Jason Ramirez.
    PROMPT

    if conversation_context&.dig(:has_context)
      base_prompt += <<~CONTEXT_PROMPT

        CONVERSATION CONTEXT GUIDANCE:
        - You have access to our recent conversation history and similar topics we've discussed
        - Reference previous discussions naturally when relevant (e.g., "Building on what we talked about earlier...")
        - If the question seems to be a follow-up, acknowledge the connection
        - Use conversation context to provide more personalized and coherent responses
        - Don't repeat information unnecessarily, but do build upon previous exchanges
      CONTEXT_PROMPT
    end

    base_prompt
  end

  def build_prompt(question, context, conversation_context = nil)
    has_frameworks = context.include?('[FRAMEWORK]')
    has_conversation_context = conversation_context&.dig(:has_context)
    
    framework_guidance = if has_frameworks
      "\n- IMPORTANT: Reference available frameworks as practical tools when relevant to the question"
    else
      ""
    end

    context_guidance = if has_conversation_context
      "\n- Use conversation context to provide continuity and build on previous discussions"
    else
      ""
    end
    
    <<~PROMPT
      Question: #{question}

      Here's relevant information from my knowledge base:

      #{context}

      IMPORTANT: Use the most relevant and specific content from the knowledge base. If you see content about specific frameworks, concepts, or personal experiences that directly relate to the question, prioritize those over generic advice. Reference specific stories, examples, and frameworks from the knowledge base when they're relevant.

      Please provide a conversational response that matches the energy and complexity of the question:
      - For simple greetings/personal questions: 1 sentence, casual and warm
      - For career/professional questions: 2-3 sentences with relevant context
      - For non-career questions: don't mention work or professional topics#{framework_guidance}#{context_guidance}
      
      Make it sound natural and personal, as if we're having a real conversation. End with a statement, not a question.
    PROMPT
  end

  def fallback_response(question, context)
    items = search_knowledge_base(question).limit(1)
    
    if items.any?
      item = items.first
      "Based on my experience with #{item.title.downcase}, #{item.content.truncate(200)}. This is from my knowledge base, and I'd be happy to elaborate on any specific aspect you're interested in."
    else
      "I don't have specific information about that in my knowledge base yet. I'd be happy to help you add relevant content, or you can ask me about topics I do have experience with."
    end
  end

  def store_conversation(question, response, user_id)
    @conversation_history << {
      question: question,
      response: response,
      timestamp: Time.current,
      user_id: user_id
    }
    
    @conversation_history = @conversation_history.last(10)
  end

  def calculate_knowledge_base_influence(relevant_items, response, question)
    return empty_kb_influence if relevant_items.nil? || relevant_items.empty?

    valid_items = relevant_items.select { |item| item.respond_to?(:confidence_score) && item.confidence_score.present? }
    
    return empty_kb_influence if valid_items.empty?

    framework_items = valid_items.select { |item| item.tags.to_s.downcase.include?('framework') }
    
    avg_confidence = valid_items.sum(&:confidence_score) / valid_items.count
    avg_relevance = valid_items.sum { |item| calculate_relevance_score(item, question) } / valid_items.count
    adjusted_confidence = avg_confidence * (avg_relevance / 100.0)
    
    influence_level = determine_influence_level(adjusted_confidence, valid_items.count, avg_relevance)
    has_content = influence_level != "minimal" && adjusted_confidence >= 0.3 && avg_relevance >= 10
    
    # Only check for generic responses if we have an actual response to check
    if has_content && response.present?
      has_content = !is_generic_response?(response, relevant_items)
    end

    # Debug logging
    Rails.logger.info "KB Influence Debug:"
    Rails.logger.info "  Question: #{question}"
    Rails.logger.info "  Items found: #{valid_items.count}"
    Rails.logger.info "  Framework items: #{framework_items.count}"
    Rails.logger.info "  Avg confidence: #{avg_confidence}"
    Rails.logger.info "  Avg relevance: #{avg_relevance}"
    Rails.logger.info "  Adjusted confidence: #{adjusted_confidence}"
    Rails.logger.info "  Influence level: #{influence_level}"
    Rails.logger.info "  Has content: #{has_content}"

    {
      has_knowledge_base_content: has_content,
      confidence_score: (adjusted_confidence * 100).round(1),
      sources_count: valid_items.count,
      influence_level: influence_level,
      raw_confidence: (avg_confidence * 100).round(1),
      avg_relevance: avg_relevance.round(1),
      sources: build_sources(valid_items, question),
      frameworks_available: framework_items.count > 0,
      framework_count: framework_items.count,
      framework_titles: framework_items.map(&:title)
    }
  end

  def determine_influence_level(confidence, count, relevance)
    case
    when confidence >= 0.5 && count >= 2 && relevance >= 30 then "high"
    when confidence >= 0.4 && count >= 1 && relevance >= 20 then "medium"
    when confidence >= 0.3 && count >= 1 && relevance >= 10 then "low"
    else "minimal"
    end
  end

  def build_sources(items, question)
    items.map do |item|
      is_framework = item.tags.to_s.downcase.include?('framework')
      
      # Handle both KnowledgeItem and KnowledgeChunk (converted to OpenStruct)
      actual_id = if item.respond_to?(:knowledge_item_id) && item.knowledge_item_id.present?
        item.knowledge_item_id  # Use parent KnowledgeItem ID for chunks
      else
        item.id
      end
      
      {
        id: actual_id,
        title: item.title,
        category: item.category,
        confidence: (item.confidence_score * 100).round(1),
        relevance_score: calculate_relevance_score(item, question),
        content_snippet: extract_relevant_snippet(item.content, question),
        word_matches: find_word_matches(item.content, question),
        is_framework: is_framework,
        tags: item.tags,
        # Include feedback-related data for the feedback processing
        feedback_score: item.respond_to?(:feedback_score) ? item.feedback_score : nil,
        total_feedback_count: item.respond_to?(:total_feedback_count) ? item.total_feedback_count : nil,
        similarity_score: item.respond_to?(:similarity_score) ? item.similarity_score : nil
      }
    end
  end

  def calculate_relevance_score(item, question)
    return 0 if question.blank? || item.content.blank?
    
    question_words = process_question_words(question)
    return 0 if question_words.empty?
    
    content_lower = item.content.downcase
    title_lower = item.title.downcase
    
    # Count meaningful word matches in content
    meaningful_matches = question_words.count { |word| content_lower.include?(word) }
    base_relevance = (meaningful_matches.to_f / question_words.length * 100).round(1)
    
    # Boost relevance if title contains meaningful question words (more generous)
    title_boost = question_words.sum { |word| title_lower.include?(word) ? 15 : 0 }
    
    # Additional boost for category matches
    category_boost = 0
    if item.category.present?
      category_lower = item.category.downcase
      category_boost = question_words.sum { |word| category_lower.include?(word) ? 10 : 0 }
    end
    
    # Boost for having multiple sources
    source_boost = [base_relevance * 0.1, 10].min
    
    total_relevance = base_relevance + title_boost + category_boost + source_boost
    [total_relevance, 100].min
  end

  def is_generic_response?(response, relevant_items)
    return true if response.blank? || relevant_items.empty?
    
    generic_phrases = [
      'dieter rams', 'jony ive', 'steve jobs', 'design thinking',
      'user experience', 'minimalist approach', 'form and function',
      'design philosophy', 'leadership principles', 'innovation',
      'creativity', 'problem solving', 'strategic thinking'
    ]
    
    response_lower = response.downcase
    generic_phrases_found = generic_phrases.any? { |phrase| response_lower.include?(phrase) }
    
    if generic_phrases_found
      has_specific_content = relevant_items.any? do |item|
        item.content.downcase.include?('dieter rams') || 
        item.content.downcase.include?('jony ive') ||
        item.content.downcase.include?('steve jobs') ||
        item.content.downcase.include?('design philosophy')
      end
      
      return !has_specific_content
    end
    
    false
  end

  def extract_relevant_snippet(content, question)
    return content.truncate(200) if question.blank?
    
    question_words = process_question_words(question)
    sentences = content.split(/[.!?]+/).map(&:strip).reject(&:blank?)
    
    best_sentence = sentences.max_by do |sentence|
      sentence.downcase.split(/\s+/).count { |word| question_words.any? { |q_word| word.include?(q_word) } }
    end
    
    best_sentence || content.truncate(200)
  end

  def find_word_matches(content, question)
    return [] if question.blank? || content.blank?
    
    question_words = process_question_words(question)
    content_lower = content.downcase
    
    question_words.select { |word| content_lower.include?(word) }.uniq
  end

  def add_inline_framework_links(text, sources)
    return text if text.blank? || sources.nil?
    
    framework_sources = sources.select { |s| s[:is_framework] }
    return text if framework_sources.empty?
    
    linked_text = text.dup
    
    framework_sources.each do |source|
      # Get the post URL for linking
      post_url = get_framework_post_url(source)
      next unless post_url
      
      # Create different patterns to match framework mentions
      patterns = build_framework_patterns(source[:title])
      
      patterns.each do |pattern|
        # Only replace if it's not already linked
        linked_text.gsub!(pattern) do |match|
          # Check if this text is already inside a markdown link
          if $`.include?('[') && !$`.rindex('[').nil? && $`.rindex('[') > ($`.rindex(']') || -1)
            match # Don't link if already inside a link
          else
            "[#{match}](#{post_url})"
          end
        end
      end
    end
    
    linked_text
  end
  
  def get_framework_post_url(source)
    return nil unless source[:category] == 'Blog Post'
    
    # Try exact match first, then try with stripped spaces
    title = source[:title]
    post = Post.where(published: true).find_by(title: title) ||
           Post.where(published: true).find_by(title: title.strip)
    
    return nil unless post
    
    # Generate the post URL (this will be processed by the frontend)
    "/posts/#{post.slug}"
  end
  
  def build_framework_patterns(title)
    patterns = []
    
    # Clean up the title
    clean_title = title.strip
    
    # Exact title match (case insensitive) - but only if it's reasonable length
    if clean_title.length < 50
      patterns << /\b#{Regexp.escape(clean_title)}\b/i
    end
    
    # Common framework naming patterns based on how AI actually references them
    case clean_title.downcase
    when /simple framework for building impactful relationships/
      patterns << /\bthree-step framework\b/i
      patterns << /\bsimple framework\b/i
      patterns << /\bset expectations,?\s*understand motivators,?\s*(?:and\s+)?achieve together\b/i
      patterns << /\bSet expectations,?\s*Understand motivators,?\s*(?:and\s+)?Achieve together\b/i
    when /validation with facebook ads/
      patterns << /\bfacebook ads experiment\b/i
      patterns << /\bfacebook ads framework\b/i
      patterns << /\bFacebook ads experiment\b/i
    when /running a lean experiment/
      patterns << /\blean experiment framework\b/i
      patterns << /\blean experiments?\b/i
      patterns << /\bstructured approach\b/i
    when /ways to pivot/
      patterns << /\bkill, pivot or preserve\b/i
      patterns << /\bkill,? pivot,? or preserve\b/i
      patterns << /\bKill, Pivot or Preserve\b/i
    when /turning constraints into better outcomes/
      patterns << /\bconstraints framework\b/i
    when /turning a team framework into company-wide impact/
      patterns << /\bteam framework\b/i
    when /from ineffective to inspired/
      patterns << /\bdiagnosis.*principles.*actions\b/i
    end
    
    # Add generic patterns that might match
    patterns << /\b#{Regexp.escape(clean_title.split.first(3).join(' '))}\b/i if clean_title.split.length >= 3
    
    patterns.compact.uniq
  end
end
