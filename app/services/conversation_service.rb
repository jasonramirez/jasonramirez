class ConversationService
  STOP_WORDS = %w[
    a an and are as at be by for from has he in is it its of on that the they to was will with
    your you what where when why how this that these those i me my myself we our ours ourselves
    is are was were been being have has had do does did will would could should may might must
    can shall ought need dare
  ].freeze

  def initialize
    api_key = ENV['OPENAI_API_KEY']
    raise "OpenAI API key not configured" if api_key.blank?
    
    @client = OpenAI::Client.new(access_token: api_key)
    @conversation_history = []
  end

  def respond_to_question(question, user_id = nil)
    begin
      relevant_items = search_knowledge_base(question)
      
      # First check if we have relevant items before calculating influence
      if relevant_items.empty?
        return build_response(
          "I don't have specific information about that in my knowledge base yet. I'd be happy to help you add relevant content, or you can ask me about topics I do have experience with.",
          empty_kb_influence
        )
      end
      
      context = build_context(relevant_items)
      response = generate_llm_response(question, context)
      store_conversation(question, response, user_id)
      
      # Calculate influence after generating response
      kb_influence = calculate_knowledge_base_influence(relevant_items, response, question)
      
      build_response(response, kb_influence)
    rescue RuntimeError => e
      # Handle configuration errors (like missing API key)
      Rails.logger.error "Configuration error in ConversationService: #{e.message}"
      build_response(
        "I'm sorry, there's a configuration issue. Please contact support.",
        empty_kb_influence
      )
    rescue => e
      Rails.logger.error "Error in ConversationService#respond_to_question: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      build_response(
        "I'm sorry, I encountered an error processing your question. Please try again.",
        empty_kb_influence
      )
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
    {
      text: text,
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
    # Progressive search strategy: start strict, then loosen
    question_words = process_question_words(question)
    return [] if question_words.empty?
    
    Rails.logger.info "Progressive Search Debug:"
    Rails.logger.info "  Question: #{question}"
    Rails.logger.info "  Question words: #{question_words}"
    
    # Tier 1: Strict search - all question words must be present
    strict_results = search_with_all_words(question_words)
    Rails.logger.info "  Tier 1 (strict) results: #{strict_results.count}"
    return strict_results if strict_results.count >= 2
    
    # Tier 2: Medium search - at least 50% of question words must be present
    medium_results = search_with_percentage_words(question_words, 0.5)
    Rails.logger.info "  Tier 2 (medium) results: #{medium_results.count}"
    return medium_results if medium_results.count >= 2
    
    # Tier 3: Loose search - any question word present (original behavior)
    loose_results = search_with_any_words(question_words)
    Rails.logger.info "  Tier 3 (loose) results: #{loose_results.count}"
    return loose_results if loose_results.count >= 1
    
    # Tier 4: Fallback - use original search method
    fallback_results = KnowledgeItem.search(question)
    Rails.logger.info "  Tier 4 (fallback) results: #{fallback_results.count}"
    fallback_results
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

  def build_context(items)
    return "No relevant information found in knowledge base." if items.empty?

    items.map do |item|
      [
        "Title: #{item.title}",
        "Category: #{item.category}",
        "Content: #{item.content}",
        "Confidence: #{(item.confidence_score * 100).round}%",
        "---"
      ]
    end.flatten.join("\n")
  end

  def generate_llm_response(question, context)
    prompt = build_prompt(question, context)
    
    begin
      response = @client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            { role: "system", content: system_prompt },
            { role: "user", content: prompt }
          ],
          max_tokens: 150,
          temperature: 0.7
        }
      )
      
      response.dig("choices", 0, "message", "content") || "I'm sorry, I couldn't generate a response at the moment."
    rescue => e
      Rails.logger.error "OpenAI API error: #{e.message}"
      fallback_response(question, context)
    end
  end

  def system_prompt
    <<~PROMPT
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

      IMPORTANT: For non-career questions, don't bring up work or professional topics unless specifically asked.

      Use the knowledge base context to provide accurate, specific information. If the context doesn't fully answer the question, acknowledge what you know and suggest what else might be helpful to explore.

      Always speak in the first person ("I", "my", "me") as Jason Ramirez.
    PROMPT
  end

  def build_prompt(question, context)
    <<~PROMPT
      Question: #{question}

      Here's relevant information from my knowledge base:

      #{context}

      Please provide a conversational response that matches the energy and complexity of the question:
      - For simple greetings/personal questions: 1 sentence, casual and warm
      - For career/professional questions: 2-3 sentences with relevant context
      - For non-career questions: don't mention work or professional topics
      
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
      sources: build_sources(valid_items, question)
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
      {
        id: item.id,
        title: item.title,
        category: item.category,
        confidence: (item.confidence_score * 100).round(1),
        relevance_score: calculate_relevance_score(item, question),
        content_snippet: extract_relevant_snippet(item.content, question),
        word_matches: find_word_matches(item.content, question)
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
end
