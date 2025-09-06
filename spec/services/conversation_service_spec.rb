require 'rails_helper'

RSpec.describe ConversationService, type: :service do
  let(:service) { ConversationService.new }
  
  describe "#respond_to_question" do
    context "without user_id" do
      it "responds without conversation context" do
        # Mock knowledge base search
        allow(service).to receive(:search_knowledge_base).and_return([])
        allow(service).to receive(:generate_llm_response).and_return("Test response")
        
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
        
        allow(service).to receive(:search_knowledge_base).and_return([])
        allow(service).to receive(:generate_llm_response).and_return("Contextual response")
        
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
        # Create more messages than we want to retrieve
        5.times { |i| create(:chat_message, chat_user: user, content: "Message #{i}", created_at: i.minutes.ago) }
        
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
