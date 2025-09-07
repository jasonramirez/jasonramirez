require 'rails_helper'

RSpec.describe ConversationService, type: :service do
  let(:client_double) { double("OpenAI::Client") }
  let(:service) { ConversationService.new }
  
  before do
    # Mock OpenAI client for all tests
    allow(OpenAI::Client).to receive(:new).and_return(client_double)
    
    # Mock embeddings API calls (used by ChatMessage model)
    allow(client_double).to receive(:embeddings).and_return({
      "data" => [
        {
          "embedding" => Array.new(1536, 0.1)
        }
      ]
    })
  end
  
  describe "#respond_to_question" do
    context "without user_id" do
      it "responds without conversation context" do
        # Mock knowledge base search to return some items so it doesn't return early
        mock_item = double("KnowledgeItem", 
                          id: 1,
                          title: "Test Item", 
                          content: "Test content", 
                          category: "Test", 
                          tags: "#test",
                          confidence_score: 0.9,
                          source: "test_source")
        allow(service).to receive(:search_knowledge_base).and_return([mock_item])
        
        # Mock OpenAI client response
        allow(client_double).to receive(:chat).and_return({
          "choices" => [
            {
              "message" => {
                "content" => "Test response"
              }
            }
          ]
        })
        
        result = service.respond_to_question("Test question")
        
        expect(result).to be_a(Hash)
        expect(result[:text]).to eq("Test response")
        expect(result[:knowledge_base_influence]).to be_present
      end
    end

    context "with user_id" do
      let!(:user) { create(:chat_user) }
      
      it "includes conversation context" do
        # Create some conversation history
        create(:chat_message, chat_user: user, content: "Previous question about design")
        
        # Mock knowledge base search to return some items
        mock_item = double("KnowledgeItem", 
                          id: 1,
                          title: "Test Item", 
                          content: "Test content", 
                          category: "Test", 
                          tags: "#test",
                          confidence_score: 0.9,
                          source: "test_source")
        allow(service).to receive(:search_knowledge_base).and_return([mock_item])
        
        # Mock OpenAI client response
        allow(client_double).to receive(:chat).and_return({
          "choices" => [
            {
              "message" => {
                "content" => "Contextual response"
              }
            }
          ]
        })
        
        result = service.respond_to_question("Follow-up question", user.id)
        
        expect(result).to be_a(Hash)
        expect(result[:text]).to eq("Contextual response")
      end
    end

    context "when errors occur" do
      it "handles OpenAI errors gracefully" do
        allow(service).to receive(:search_knowledge_base).and_raise(OpenAI::Error.new("API Error"))
        
        result = service.respond_to_question("Test question")
        
        expect(result[:text]).to include("connectivity issues")
      end

      it "handles database errors gracefully" do
        allow(service).to receive(:search_knowledge_base).and_raise(ActiveRecord::StatementInvalid.new("DB Error"))
        
        result = service.respond_to_question("Test question")
        
        expect(result[:text]).to include("trouble accessing")
      end

      it "handles general errors gracefully" do
        allow(service).to receive(:search_knowledge_base).and_raise(StandardError.new("Unknown error"))
        
        result = service.respond_to_question("Test question")
        
        expect(result[:text]).to include("encountered an error")
      end
    end
  end

  describe "#get_conversation_context" do
    let!(:user) { create(:chat_user) }
    
    context "with recent messages" do
      let!(:oldest_message) { create(:chat_message, chat_user: user, content: "Oldest question", created_at: 3.hours.ago) }
      let!(:middle_message) { create(:chat_message, :answer, chat_user: user, content: "Middle answer", created_at: 2.hours.ago) }
      let!(:newest_message) { create(:chat_message, chat_user: user, content: "Latest question", created_at: 1.hour.ago) }
      
      it "retrieves recent conversation history in correct order" do
        context = service.send(:get_conversation_context, "Follow-up question", user.id)
        
        expect(context[:recent_messages].count).to eq(3)
        expect(context[:has_context]).to be true
        
        # Should be in reverse chronological order (newest first)
        messages = context[:recent_messages].first(3)
        expect(messages[0]).to eq(newest_message)
        expect(messages[1]).to eq(middle_message) 
        expect(messages[2]).to eq(oldest_message)
      end

      it "limits recent messages to specified count" do
        # Create more messages than we want to retrieve (15 total to test the 10 limit)
        12.times { |i| create(:chat_message, chat_user: user, content: "Message #{i}", created_at: i.minutes.ago) }
        
        context = service.send(:get_conversation_context, "Follow-up question", user.id)
        
        expect(context[:recent_messages].count).to eq(10) # Default limit in get_conversation_context
      end
    end

    context "with conversation about design systems" do
      before do
        create(:chat_message, chat_user: user, content: "How do you think about design systems?", created_at: 30.minutes.ago)
        create(:chat_message, :answer, chat_user: user, content: "Design systems are essential for creating consistency...", created_at: 25.minutes.ago)
      end

      it "finds design systems context for follow-up questions" do
        context = service.send(:get_conversation_context, "Say more", user.id)
        
        expect(context[:has_context]).to be true
        recent_content = context[:recent_messages].map(&:content).join(" ")
        expect(recent_content).to include("design systems")
      end
    end

    context "without conversation history" do
      it "returns empty context" do
        context = service.send(:get_conversation_context, "First question", user.id)
        
        expect(context[:recent_messages]).to be_empty
        expect(context[:has_context]).to be false
      end
    end
  end

  describe "#search_knowledge_base" do
    context "with knowledge chunks available" do
      let!(:knowledge_item) { create(:knowledge_item, title: "Design Principles") }
      let!(:chunk) { create(:knowledge_chunk, knowledge_item: knowledge_item, content: "Chunk about design") }
      
      it "attempts chunk search first" do
        # Create chunk doubles with similarity scores
        chunk_with_score = double('KnowledgeChunk',
          id: 1,
          title: 'Test Chunk',
          content: 'Test content',
          category: 'Test',
          tags: '#test',
          confidence_score: 0.9,
          similarity_score: 0.3,
          source: 'test_source',
          chunk_type: 'semantic',
          chunk_index: 0,
          knowledge_item_id: 1
        )
        
        allow(KnowledgeChunk).to receive(:semantic_search).and_return([chunk_with_score])
        
        result = service.send(:search_knowledge_base, "design principles")
        
        expect(KnowledgeChunk).to have_received(:semantic_search)
        expect(result).not_to be_empty
      end
    end

    context "when chunk search fails" do
      it "falls back to knowledge item search" do
        allow(KnowledgeChunk).to receive(:semantic_search).and_return([])
        allow(KnowledgeItem).to receive(:semantic_search).and_return([])
        allow(service).to receive(:progressive_keyword_search).and_return([])
        
        service.send(:search_knowledge_base, "test query")
        
        expect(KnowledgeItem).to have_received(:semantic_search)
      end
    end

    context "with feedback-aware search" do
      it "passes search query to enhanced semantic search methods" do
        # Mock the enhanced semantic search methods
        expect(KnowledgeChunk).to receive(:semantic_search).with("design feedback test", limit: 8).and_return([])
        expect(KnowledgeItem).to receive(:semantic_search).with("design feedback test", limit: 6).and_return([])
        allow(service).to receive(:progressive_keyword_search).and_return([])
        
        service.send(:search_knowledge_base, "design feedback test")
      end

      it "prioritizes chunks and items with good feedback scores in search results" do
        # This test verifies that the search methods are called with the query
        # The actual feedback-aware ranking is tested in the model specs
        good_chunk = double('KnowledgeChunk',
          id: 1, title: 'Good Content', content: 'Well-rated content', 
          category: 'Test', tags: '#test', confidence_score: 0.9,
          similarity_score: 0.3, source: 'test', chunk_type: 'semantic',
          chunk_index: 0, knowledge_item_id: 1
        )
        
        allow(KnowledgeChunk).to receive(:semantic_search).and_return([good_chunk])
        
        result = service.send(:search_knowledge_base, "test query")
        
        expect(result).to include(satisfy { |item| item.respond_to?(:title) && item.title == 'Good Content' })
      end
    end
  end

  describe "#convert_chunk_to_item_format" do
    let(:knowledge_item) { create(:knowledge_item) }
    let(:chunk) { create(:knowledge_chunk, knowledge_item: knowledge_item) }
    
    it "converts chunk to OpenStruct with item-like interface" do
      result = service.send(:convert_chunk_to_item_format, chunk)
      
      expect(result).to respond_to(:id)
      expect(result).to respond_to(:title)
      expect(result).to respond_to(:content)
      expect(result).to respond_to(:category)
      expect(result.id).to eq("chunk_#{chunk.id}")
    end

    it "handles chunks with similarity scores" do
      # Create a double that responds to similarity_score
      chunk_with_score = double('KnowledgeChunk',
        id: 1,
        title: 'Test Chunk',
        content: 'Test content',
        category: 'Test',
        tags: '#test',
        confidence_score: 0.9,
        similarity_score: 0.75,
        source: 'test_source',
        chunk_type: 'semantic',
        chunk_index: 0,
        knowledge_item_id: 1
      )
      
      result = service.send(:convert_chunk_to_item_format, chunk_with_score)
      
      expect(result.similarity_score).to eq(0.75)
    end

    context "with feedback integration" do
      let!(:knowledge_item_with_feedback) { 
        create(:knowledge_item, 
               feedback_score: 0.8, 
               total_feedback_count: 5.0, 
               positive_feedback_count: 4.0) 
      }
      let(:chunk_with_feedback) { create(:knowledge_chunk, knowledge_item: knowledge_item_with_feedback) }

      it "includes feedback scores from parent KnowledgeItem" do
        result = service.send(:convert_chunk_to_item_format, chunk_with_feedback)
        
        expect(result.feedback_score).to eq(0.8)
        expect(result.total_feedback_count).to eq(5.0)
        expect(result.positive_feedback_count).to eq(4.0)
        expect(result.knowledge_item_id).to eq(knowledge_item_with_feedback.id)
      end

      it "handles chunks when parent item has no feedback" do
        result = service.send(:convert_chunk_to_item_format, chunk)
        
        expect(result.feedback_score).to eq(0.5) # Default score
        expect(result.total_feedback_count).to eq(0.0)
        expect(result.positive_feedback_count).to eq(0.0)
      end
    end
  end

  describe "#build_context" do
    context "with conversation context" do
      let!(:user) { create(:chat_user) }
      let!(:oldest_message) { create(:chat_message, chat_user: user, content: "Oldest question", created_at: 2.hours.ago) }
      let!(:newest_message) { create(:chat_message, :answer, chat_user: user, content: "Most recent answer about design systems", created_at: 1.hour.ago) }
      
      let(:conversation_context) do
        {
          recent_messages: [newest_message, oldest_message], # Newest first
          similar_messages: [],
          has_context: true
        }
      end
      
      it "includes conversation context in the output" do
        result = service.send(:build_context, [], conversation_context)
        
        expect(result).to include("CONVERSATION CONTEXT:")
        expect(result).to include("Recent conversation:")
        expect(result).to include("Most recent answer about design systems")
      end

      it "uses the most recent messages first (not last)" do
        result = service.send(:build_context, [], conversation_context)
        
        # Should include the newest message first
        lines = result.split("\n")
        recent_conversation_index = lines.find_index("Recent conversation:")
        first_message_line = lines[recent_conversation_index + 1]
        
        expect(first_message_line).to include("Most recent answer about design systems")
      end
    end

    context "with design systems conversation" do
      let!(:user) { create(:chat_user) }
      let!(:design_question) { create(:chat_message, chat_user: user, content: "How do you think about design systems?") }
      let!(:design_answer) { create(:chat_message, :answer, chat_user: user, content: "Design systems are essential for creating consistency...") }
      
      let(:conversation_context) do
        {
          recent_messages: [design_answer, design_question],
          similar_messages: [],
          has_context: true
        }
      end

      it "preserves design systems context for follow-up questions" do
        result = service.send(:build_context, [], conversation_context)
        
        expect(result).to include("design systems")
        expect(result).to include("consistency")
      end
    end

    context "with framework items" do
      let(:framework_item) { 
        double("KnowledgeItem", 
               tags: "#framework, #design", 
               title: "Design Framework",
               category: "Framework",
               content: "Framework content",
               confidence_score: 0.9) 
      }
      
      it "adds framework notice" do
        result = service.send(:build_context, [framework_item])
        
        expect(result).to include("FRAMEWORKS AVAILABLE:")
      end
    end

    context "with no items" do
      it "returns no relevant information message" do
        result = service.send(:build_context, [])
        
        expect(result).to eq("No relevant information found in knowledge base.")
      end
    end
  end

  describe "#build_sources" do
    let(:mock_item) do
      double("KnowledgeItem",
        id: 1,
        title: "Test Item",
        content: "Test content about design patterns",
        category: "Design",
        tags: "#design, #patterns",
        confidence_score: 0.9,
        feedback_score: 0.75,
        total_feedback_count: 8.0,
        positive_feedback_count: 6.0,
        similarity_score: 0.4
      )
    end

    it "includes feedback data in source information" do
      sources = service.send(:build_sources, [mock_item], "design patterns")
      
      expect(sources).to be_an(Array)
      expect(sources.length).to eq(1)
      
      source = sources.first
      expect(source[:id]).to eq(1)
      expect(source[:title]).to eq("Test Item")
      expect(source[:feedback_score]).to eq(0.75)
      expect(source[:total_feedback_count]).to eq(8.0)
      expect(source[:similarity_score]).to eq(0.4)
    end

    context "with chunk items" do
      let(:mock_chunk_item) do
        double("ConvertedChunk",
          id: "chunk_5",
          title: "Chunk Title",
          content: "Chunk content",
          category: "Design",
          tags: "#framework",
          confidence_score: 0.8,
          knowledge_item_id: 10,
          feedback_score: 0.9,
          total_feedback_count: 12.0,
          similarity_score: 0.3
        )
      end

      it "uses parent KnowledgeItem ID for chunks" do
        sources = service.send(:build_sources, [mock_chunk_item], "test query")
        
        source = sources.first
        expect(source[:id]).to eq(10) # Parent KnowledgeItem ID, not chunk ID
        expect(source[:feedback_score]).to eq(0.9)
        expect(source[:is_framework]).to be true
      end
    end

    context "with items missing feedback data" do
      let(:mock_item_no_feedback) do
        double("KnowledgeItem",
          id: 2,
          title: "Item Without Feedback",
          content: "Some content",
          category: "Test",
          tags: "#test",
          confidence_score: 0.7
        )
      end

      it "handles items without feedback gracefully" do
        sources = service.send(:build_sources, [mock_item_no_feedback], "test")
        
        source = sources.first
        expect(source[:id]).to eq(2)
        expect(source[:feedback_score]).to be_nil
        expect(source[:total_feedback_count]).to be_nil
        expect(source[:similarity_score]).to be_nil
      end
    end
  end

  describe "private methods" do
    describe "#build_prompt" do
      it "includes framework guidance when frameworks are present" do
        context_with_framework = "Some content [FRAMEWORK] more content"
        
        prompt = service.send(:build_prompt, "Test question", context_with_framework)
        
        expect(prompt).to include("Reference available frameworks")
      end

      it "includes conversation context guidance when context is present" do
        conversation_context = { has_context: true }
        
        prompt = service.send(:build_prompt, "Test question", "context", conversation_context)
        
        expect(prompt).to include("Use conversation context")
      end
    end

    describe "#system_prompt" do
      it "includes conversation guidance when context is available" do
        conversation_context = { has_context: true }
        
        prompt = service.send(:system_prompt, conversation_context)
        
        expect(prompt).to include("CONVERSATION CONTEXT GUIDANCE")
      end

      it "excludes conversation guidance when no context" do
        prompt = service.send(:system_prompt, nil)
        
        expect(prompt).not_to include("CONVERSATION CONTEXT GUIDANCE")
      end
    end
  end
end
