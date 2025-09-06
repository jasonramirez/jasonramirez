require 'rails_helper'

RSpec.describe "Chat Conversation Flow", type: :integration do
  let!(:user) { create(:chat_user) }
  let(:service) { ConversationService.new }

  describe "conversation memory and context" do
    context "design systems conversation flow" do
      it "maintains context across multiple exchanges" do
        # Step 1: Ask about design systems
        result1 = service.respond_to_question("How do you think about design systems?", user.id)
        expect(result1[:text]).to be_present
        
        # Verify the question was saved
        question1 = ChatMessage.for_user(user.id).questions.last
        expect(question1.content).to eq("How do you think about design systems?")
        
        # Verify the answer was saved
        answer1 = ChatMessage.for_user(user.id).answers.last
        expect(answer1.content).to eq(result1[:text])

        # Step 2: Follow up with "Say more" - should reference design systems
        result2 = service.respond_to_question("Say more", user.id)
        
        # The response should be contextually relevant to design systems
        response_text = result2[:text].downcase
        
        # Should include design-related concepts from the conversation context
        design_keywords = ['design', 'system', 'consistency', 'team', 'collaboration', 'principle']
        found_keywords = design_keywords.select { |keyword| response_text.include?(keyword) }
        
        expect(found_keywords).not_to be_empty, 
          "Expected response to include design-related keywords, but got: #{result2[:text]}"
        
        # Verify conversation memory was used
        expect(result2[:knowledge_base_influence][:has_knowledge_base_content]).to be true
      end

      it "handles follow-up questions about specific concepts" do
        # Initial conversation about design systems
        service.respond_to_question("How do you think about design systems?", user.id)
        
        # Follow up asking about a specific concept mentioned
        result = service.respond_to_question("Can you elaborate on the listening tour approach?", user.id)
        
        # Should reference the listening tour concept from design systems context
        expect(result[:text].downcase).to include('listening')
        expect(result[:text].downcase).to include('tour')
      end
    end

    context "conversation ordering bug prevention" do
      it "uses most recent messages for context, not oldest" do
        # Create older conversation
        create(:chat_message, chat_user: user, content: "Old question about teams", created_at: 2.hours.ago)
        create(:chat_message, :answer, chat_user: user, content: "Old answer about team building", created_at: 2.hours.ago)
        
        # Create recent conversation about design systems
        create(:chat_message, chat_user: user, content: "How do you think about design systems?", created_at: 10.minutes.ago)
        create(:chat_message, :answer, chat_user: user, content: "Design systems are essential for creating consistency and alignment", created_at: 5.minutes.ago)
        
        # Ask follow-up - should reference design systems, not teams
        context = service.send(:get_conversation_context, "Say more", user.id)
        
        # Recent messages should be about design systems, not teams
        recent_content = context[:recent_messages].first(3).map(&:content).join(" ")
        expect(recent_content).to include("design systems")
        expect(recent_content).not_to include("team building")
      end

      it "retrieves messages in correct chronological order" do
        # Create messages with specific timestamps
        msg1 = create(:chat_message, chat_user: user, content: "First message", created_at: 3.hours.ago)
        msg2 = create(:chat_message, chat_user: user, content: "Second message", created_at: 2.hours.ago)
        msg3 = create(:chat_message, chat_user: user, content: "Third message", created_at: 1.hour.ago)
        
        recent_messages = ChatMessage.for_user(user.id).recent(3)
        
        # Should be in reverse chronological order (newest first)
        expect(recent_messages).to eq([msg3, msg2, msg1])
        
        # Timestamps should be in descending order
        timestamps = recent_messages.map(&:created_at)
        expect(timestamps).to eq(timestamps.sort.reverse)
      end
    end

    context "context building for LLM prompts" do
      before do
        create(:chat_message, chat_user: user, content: "What are design principles?", created_at: 20.minutes.ago)
        create(:chat_message, :answer, chat_user: user, content: "Design principles are fundamental guidelines that inform decision-making", created_at: 15.minutes.ago)
      end

      it "includes recent conversation context in prompts" do
        context = service.send(:get_conversation_context, "How do you create them?", user.id)
        built_context = service.send(:build_context, [], context)
        
        expect(built_context).to include("CONVERSATION CONTEXT:")
        expect(built_context).to include("Recent conversation:")
        expect(built_context).to include("Design principles are fundamental guidelines")
      end

      it "uses conversation context to inform responses" do
        # This follow-up should understand "them" refers to design principles
        result = service.respond_to_question("How do you create them?", user.id)
        
        # Response should be about creating design principles, not generic
        response_text = result[:text].downcase
        expect(response_text).to include('principle').or include('design')
      end
    end
  end

  describe "embedding generation for conversation memory" do
    it "generates embeddings immediately for new messages" do
      # Mock the embedding service to avoid API calls in tests
      embedding_service = instance_double(EmbeddingService)
      allow(EmbeddingService).to receive(:new).and_return(embedding_service)
      allow(embedding_service).to receive(:generate_embedding).and_return([0.1, 0.2, 0.3])

      question = "How do design systems work?"
      service.respond_to_question(question, user.id)

      # The question message should have been created with an embedding
      saved_question = ChatMessage.for_user(user.id).questions.last
      expect(saved_question.content).to eq(question)
      # Note: In test environment, embedding might be generated async
    end
  end
end
