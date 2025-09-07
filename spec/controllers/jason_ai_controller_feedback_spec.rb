require 'rails_helper'

RSpec.describe JasonAiController, type: :controller do
  let(:chat_user) { create(:chat_user) }
  
  before do
    # Mock session-based authentication
    session[:chat_user_id] = chat_user.id
  end

  describe 'POST #feedback' do
    let(:chat_message) { create(:chat_message, chat_user: chat_user, message_type: 'answer') }
    let!(:knowledge_item1) { create(:knowledge_item, title: 'Test Item 1') }
    let!(:knowledge_item2) { create(:knowledge_item, title: 'Test Item 2') }

    before do
      # Set up message metadata with knowledge base influence
      chat_message.update!(metadata: {
        knowledge_base_influence: {
          sources: [
            {
              id: knowledge_item1.id,
              title: knowledge_item1.title,
              relevance_score: 0.9
            },
            {
              id: knowledge_item2.id,
              title: knowledge_item2.title,
              relevance_score: 0.6
            }
          ]
        }
      })
    end

    context 'with valid parameters' do
      context 'positive feedback' do
        it 'updates message metadata with feedback' do
          post :feedback, params: { message_id: chat_message.id, rating: 'thumbs_up' }, format: :json
          
          chat_message.reload
          feedback_data = chat_message.metadata['user_feedback']
          
          expect(feedback_data['rating']).to eq('thumbs_up')
          expect(feedback_data['user_id']).to eq(chat_user.id)
          expect(feedback_data['submitted_at']).to be_present
        end

        it 'updates knowledge items with weighted positive feedback' do
          expect {
            post :feedback, params: { message_id: chat_message.id, rating: 'thumbs_up' }, format: :json
          }.to change { knowledge_item1.reload.positive_feedback_count }.by(1.0)
           .and change { knowledge_item1.reload.total_feedback_count }.by(1.0)
           .and change { knowledge_item2.reload.positive_feedback_count }.by(0.7)
           .and change { knowledge_item2.reload.total_feedback_count }.by(0.7)
        end

        it 'updates knowledge items feedback scores' do
          post :feedback, params: { message_id: chat_message.id, rating: 'thumbs_up' }, format: :json
          
          knowledge_item1.reload
          knowledge_item2.reload
          
          # Both should have improved scores (above baseline 0.5)
          expect(knowledge_item1.feedback_score).to be > 0.5
          expect(knowledge_item2.feedback_score).to be > 0.5
          
          # High relevance item should get better score improvement
          expect(knowledge_item1.feedback_score).to be > knowledge_item2.feedback_score
        end

        it 'returns success response' do
          post :feedback, params: { message_id: chat_message.id, rating: 'thumbs_up' }, format: :json
          
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response['status']).to eq('success')
          expect(json_response['feedback']['rating']).to eq('thumbs_up')
        end
      end

      context 'negative feedback' do
        it 'updates message metadata with negative feedback' do
          post :feedback, params: { message_id: chat_message.id, rating: 'thumbs_down' }, format: :json
          
          chat_message.reload
          feedback_data = chat_message.metadata['user_feedback']
          
          expect(feedback_data['rating']).to eq('thumbs_down')
        end

        it 'updates knowledge items with weighted negative feedback' do
          expect {
            post :feedback, params: { message_id: chat_message.id, rating: 'thumbs_down' }, format: :json
          }.to change { knowledge_item1.reload.positive_feedback_count }.by(0)
           .and change { knowledge_item1.reload.total_feedback_count }.by(1.0)
           .and change { knowledge_item2.reload.positive_feedback_count }.by(0)
           .and change { knowledge_item2.reload.total_feedback_count }.by(0.7)
        end

        it 'decreases knowledge items feedback scores' do
          post :feedback, params: { message_id: chat_message.id, rating: 'thumbs_down' }, format: :json
          
          knowledge_item1.reload
          knowledge_item2.reload
          
          # Both should have decreased scores (below baseline 0.5)
          expect(knowledge_item1.feedback_score).to be < 0.5
          expect(knowledge_item2.feedback_score).to be < 0.5
        end
      end

      context 'duplicate feedback from same user' do
        before do
          # Submit initial feedback
          post :feedback, params: { message_id: chat_message.id, rating: 'thumbs_up' }, format: :json
        end

        it 'overwrites previous feedback in message metadata' do
          # Submit different feedback (should overwrite message metadata)
          post :feedback, params: { message_id: chat_message.id, rating: 'thumbs_down' }, format: :json
          
          chat_message.reload
          expect(chat_message.metadata['user_feedback']['rating']).to eq('thumbs_down')
        end

        it 'accumulates feedback in knowledge base for aggregative learning' do
          # In an aggregative system, we treat each feedback submission as potentially from different users
          # So the knowledge base gets cumulative feedback for better learning
          expect {
            post :feedback, params: { message_id: chat_message.id, rating: 'thumbs_down' }, format: :json
          }.to change { knowledge_item1.reload.total_feedback_count }.by(1.0)
          
          # Note: This simulates multiple users giving feedback on the same response
          # In real usage, different users would have different messages referencing same knowledge
        end
      end
    end

    context 'with invalid parameters' do
      it 'returns error for invalid rating' do
        post :feedback, params: { message_id: chat_message.id, rating: 'invalid_rating' }, format: :json
        
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid feedback rating')
      end

      it 'returns error for non-existent message' do
        post :feedback, params: { message_id: 99999, rating: 'thumbs_up' }, format: :json
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Message not found')
      end

      it 'returns error for message belonging to different user' do
        other_user = create(:chat_user)
        other_message = create(:chat_message, chat_user: other_user, message_type: 'answer')
        
        post :feedback, params: { message_id: other_message.id, rating: 'thumbs_up' }, format: :json
        
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'without authentication' do
      before do
        session[:chat_user_id] = nil
      end

      it 'redirects to login' do
        post :feedback, params: { message_id: chat_message.id, rating: 'thumbs_up' }, format: :json
        
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'message without knowledge base sources' do
      let(:simple_message) { create(:chat_message, chat_user: chat_user, message_type: 'answer', metadata: {}) }

      it 'updates message feedback but does not affect knowledge items' do
        expect {
          post :feedback, params: { message_id: simple_message.id, rating: 'thumbs_up' }, format: :json
        }.not_to change { knowledge_item1.reload.feedback_score }
        
        simple_message.reload
        expect(simple_message.metadata['user_feedback']['rating']).to eq('thumbs_up')
        expect(response).to have_http_status(:ok)
      end
    end

    context 'relevance weight calculation' do
      let(:high_relevance_message) do
        msg = create(:chat_message, chat_user: chat_user, message_type: 'answer')
        msg.update!(metadata: {
          knowledge_base_influence: {
            sources: [
              { id: knowledge_item1.id, title: knowledge_item1.title, relevance_score: 0.95 }, # High
              { id: knowledge_item2.id, title: knowledge_item2.title, relevance_score: 0.3 }   # Low
            ]
          }
        })
        msg
      end

      it 'applies different weights based on relevance scores' do
        expect {
          post :feedback, params: { message_id: high_relevance_message.id, rating: 'thumbs_up' }, format: :json
        }.to change { knowledge_item1.reload.total_feedback_count }.by(1.0)    # High relevance gets full weight
         .and change { knowledge_item2.reload.total_feedback_count }.by(0.1)    # Low relevance gets minimal weight
      end
    end
  end

  describe 'private methods' do
    let(:controller_instance) { JasonAiController.new }
    let(:knowledge_item) { create(:knowledge_item) }

    describe '#calculate_relevance_weight' do
      it 'returns full weight for high relevance' do
        source_data = { 'relevance_score' => 0.9 }
        weight = controller_instance.send(:calculate_relevance_weight, source_data)
        expect(weight).to eq(1.0)
      end

      it 'returns partial weight for medium relevance' do
        source_data = { 'relevance_score' => 0.65 }
        weight = controller_instance.send(:calculate_relevance_weight, source_data)
        expect(weight).to eq(0.7)
      end

      it 'returns minimal weight for low relevance' do
        source_data = { 'relevance_score' => 0.2 }
        weight = controller_instance.send(:calculate_relevance_weight, source_data)
        expect(weight).to eq(0.1)
      end

      it 'handles missing relevance score' do
        source_data = {}
        weight = controller_instance.send(:calculate_relevance_weight, source_data)
        expect(weight).to eq(0.4) # Default for 0.5 relevance
      end
    end

    describe '#find_knowledge_item' do
      it 'finds knowledge item by ID' do
        source_data = { 'id' => knowledge_item.id }
        found_item = controller_instance.send(:find_knowledge_item, source_data)
        expect(found_item).to eq(knowledge_item)
      end

      it 'finds knowledge item by title when ID is missing' do
        source_data = { 'title' => knowledge_item.title }
        found_item = controller_instance.send(:find_knowledge_item, source_data)
        expect(found_item).to eq(knowledge_item)
      end

      it 'returns nil when item not found' do
        source_data = { 'id' => 99999 }
        found_item = controller_instance.send(:find_knowledge_item, source_data)
        expect(found_item).to be_nil
      end
    end
  end
end
