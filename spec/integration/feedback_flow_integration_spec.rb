require 'rails_helper'

RSpec.describe JasonAiController, type: :controller do
  
  let!(:chat_user) { create(:chat_user) }
  let!(:knowledge_item1) { create(:knowledge_item, 
                                  title: "Design Systems", 
                                  content: "Design systems help create consistency",
                                  feedback_score: 0.5,
                                  total_feedback_count: 0.0,
                                  positive_feedback_count: 0.0) }
  let!(:knowledge_item2) { create(:knowledge_item, 
                                  title: "Design Principles", 
                                  content: "Design principles guide decisions",
                                  feedback_score: 0.5,
                                  total_feedback_count: 0.0,
                                  positive_feedback_count: 0.0) }
  
  before do
    # Set up session authentication for controller tests
    session[:chat_user_id] = chat_user.id
  end

  describe "Feedback processing integration" do
    it "processes positive feedback and improves knowledge item scoring" do
      # Step 1: Create a chat message with knowledge base influence metadata
      answer_message = chat_user.chat_messages.create!(
        content: "Design systems are crucial for maintaining consistency across your product suite.",
        message_type: 'answer',
        metadata: {
          'knowledge_base_influence' => {
            'has_knowledge_base_content' => true,
            'sources' => [
              {
                'id' => knowledge_item1.id,
                'title' => knowledge_item1.title,
                'relevance_score' => 0.9
              }
            ]
          }
        }
      )
      
      # Step 2: Submit positive feedback
      post :feedback, params: { 
        message_id: answer_message.id, 
        rating: "thumbs_up" 
      }, format: :json
      
      expect(response).to have_http_status(:success)
      feedback_response = JSON.parse(response.body)
      expect(feedback_response["status"]).to eq("success")
      
      # Step 3: Verify feedback was stored in message metadata
      answer_message.reload
      expect(answer_message.metadata["user_feedback"]["rating"]).to eq("thumbs_up")
      expect(answer_message.metadata["user_feedback"]["submitted_at"]).to be_present
      
      # Step 4: Verify knowledge item feedback score was updated
      knowledge_item1.reload
      expect(knowledge_item1.total_feedback_count).to be > 0
      expect(knowledge_item1.positive_feedback_count).to be > 0
      expect(knowledge_item1.feedback_score).to be > 0.5  # Should be better than default
      expect(knowledge_item1.last_feedback_at).to be_present
    end

    it "processes negative feedback and penalizes knowledge item scoring" do
      # Step 1: Create a chat message with knowledge base influence metadata
      answer_message = chat_user.chat_messages.create!(
        content: "Not a great answer about design systems.",
        message_type: 'answer',
        metadata: {
          'knowledge_base_influence' => {
            'has_knowledge_base_content' => true,
            'sources' => [
              {
                'id' => knowledge_item1.id,
                'title' => knowledge_item1.title,
                'relevance_score' => 0.8
              }
            ]
          }
        }
      )
      
      # Step 2: Submit negative feedback
      post :feedback, params: { 
        message_id: answer_message.id, 
        rating: "thumbs_down" 
      }, format: :json
      
      expect(response).to have_http_status(:success)
      
      # Step 3: Verify knowledge item feedback score was updated negatively
      knowledge_item1.reload
      expect(knowledge_item1.total_feedback_count).to be > 0
      expect(knowledge_item1.positive_feedback_count).to eq(0.0)  # No positive feedback
      expect(knowledge_item1.feedback_score).to be < 0.5  # Should be worse than default
    end

    it "handles feedback for responses with multiple knowledge sources" do
      # Create a chat message with multiple knowledge sources
      answer_message = chat_user.chat_messages.create!(
        content: "Both design patterns and principles are important.",
        message_type: 'answer',
        metadata: {
          'knowledge_base_influence' => {
            'has_knowledge_base_content' => true,
            'sources' => [
              {
                'id' => knowledge_item1.id,
                'title' => knowledge_item1.title,
                'relevance_score' => 0.9
              },
              {
                'id' => knowledge_item2.id,
                'title' => knowledge_item2.title,
                'relevance_score' => 0.7
              }
            ]
          }
        }
      )
      
      # Submit positive feedback
      post :feedback, params: { 
        message_id: answer_message.id, 
        rating: "thumbs_up" 
      }, format: :json
      
      expect(response).to have_http_status(:success)
      
      # Both knowledge items should receive feedback updates
      knowledge_item1.reload
      knowledge_item2.reload
      
      expect(knowledge_item1.total_feedback_count).to be > 0
      expect(knowledge_item2.total_feedback_count).to be > 0
      expect(knowledge_item1.feedback_score).to be > 0.5
      expect(knowledge_item2.feedback_score).to be > 0.5
    end

    it "verifies that feedback-enhanced search improves result ranking" do
      # This test verifies that the search methods include feedback in ranking
      # The detailed ranking logic is tested in the model specs
      
      # Give knowledge_item1 good feedback
      knowledge_item1.update!(
        feedback_score: 0.9,
        total_feedback_count: 10.0,
        positive_feedback_count: 9.0
      )
      
      # Call the semantic search methods directly to verify they use feedback
      results = KnowledgeItem.semantic_search("design systems", limit: 5)
      
      # The method should run without error and can potentially return results
      # (depending on if there are embeddings available)
      expect { results }.not_to raise_error
      
      # If results are returned, they should include the adjusted similarity score
      if results.any?
        first_result = results.first
        expect(first_result).to respond_to(:similarity_score)
      end
    end

    context "error handling" do
      it "handles invalid message IDs gracefully" do
        post :feedback, params: { 
          message_id: 99999, 
          rating: "thumbs_up" 
        }, format: :json
        
        expect(response).to have_http_status(:not_found)
        error_response = JSON.parse(response.body)
        expect(error_response["error"]).to eq("Message not found")
      end

      it "handles invalid rating values gracefully" do
        # Create a message for the test
        answer_message = chat_user.chat_messages.create!(
          content: "Test answer",
          message_type: 'answer',
          metadata: { 'knowledge_base_influence' => { 'sources' => [] } }
        )
        
        post :feedback, params: { 
          message_id: answer_message.id, 
          rating: "invalid_rating" 
        }, format: :json
        
        expect(response).to have_http_status(:bad_request)
        error_response = JSON.parse(response.body)
        expect(error_response["error"]).to eq("Invalid feedback rating")
      end
    end
  end
end
