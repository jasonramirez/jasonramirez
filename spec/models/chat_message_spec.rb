require 'rails_helper'

RSpec.describe ChatMessage, type: :model do
  describe "validations" do
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:message_type) }
    it { should validate_inclusion_of(:message_type).in_array(%w[question answer]) }
  end

  describe "associations" do
    it { should belong_to(:chat_user) }
  end

  describe "scopes" do
    let(:user) { create(:chat_user) }
    let(:question1) { create(:chat_message, chat_user: user, message_type: 'question', created_at: 1.hour.ago) }
    let(:answer1) { create(:chat_message, chat_user: user, message_type: 'answer', created_at: 50.minutes.ago) }
    let(:question2) { create(:chat_message, chat_user: user, message_type: 'question', created_at: 30.minutes.ago) }

    describe ".for_user" do
      it "returns messages for specific user" do
        # Create test data
        question1
        answer1 
        question2
        
        other_user = create(:chat_user)
        create(:chat_message, chat_user: other_user)
        
        expect(ChatMessage.for_user(user.id)).to contain_exactly(question1, answer1, question2)
      end
    end

    describe ".ordered" do
      it "returns messages in chronological order" do
        # Create test data
        question1
        answer1
        question2
        
        expect(ChatMessage.for_user(user.id).ordered).to eq([question1, answer1, question2])
      end
    end

    describe ".recent" do
      it "limits results to specified number" do
        # Create test data
        question1
        answer1
        question2
        
        expect(ChatMessage.for_user(user.id).recent(2)).to eq([question2, answer1])
      end

      it "returns messages in reverse chronological order (newest first)" do
        # Create test data
        question1
        answer1
        question2
        
        # This test would have caught our bug!
        result = ChatMessage.for_user(user.id).recent(3)
        expect(result).to eq([question2, answer1, question1])
        
        # Verify timestamps are in descending order
        timestamps = result.map(&:created_at)
        expect(timestamps).to eq(timestamps.sort.reverse)
      end

      it "returns most recent messages when more exist than limit" do
        # Create test data
        question1
        answer1
        question2
        
        # Create additional older message
        old_message = create(:chat_message, chat_user: user, created_at: 2.hours.ago)
        
        result = ChatMessage.for_user(user.id).recent(2)
        expect(result).to eq([question2, answer1])
        expect(result).not_to include(old_message)
      end
    end

    describe ".questions" do
      it "returns only question messages" do
        # Create test data
        question1
        answer1
        question2
        
        expect(ChatMessage.questions).to contain_exactly(question1, question2)
      end
    end

    describe ".answers" do
      it "returns only answer messages" do
        # Create test data
        question1
        answer1
        question2
        
        expect(ChatMessage.answers).to contain_exactly(answer1)
      end
    end

    describe ".with_embeddings" do
      it "returns only messages with embeddings" do
        user = create(:chat_user)
        
        # Create message with embedding by directly setting the embedding
        message_with_embedding = create(:chat_message, chat_user: user)
        # Use raw SQL to set a vector embedding since we have the column
        embedding_array = Array.new(3072, 0.1) # Create a test embedding
        formatted_embedding = "[#{embedding_array.join(',')}]"
        ActiveRecord::Base.connection.execute(
          "UPDATE chat_messages SET content_embedding = '#{formatted_embedding}' WHERE id = #{message_with_embedding.id}"
        )
        
        # Create message without embedding
        message_without_embedding = create(:chat_message, chat_user: user)
        
        # Test the scope
        messages_with_embeddings = ChatMessage.with_embeddings
        
        expect(messages_with_embeddings).to include(message_with_embedding)
        expect(messages_with_embeddings).not_to include(message_without_embedding)
      end
    end
  end

  describe "embedding generation" do
    let(:message) { build(:chat_message) }

    # Override the global stubbing for these embedding tests
    before do
      allow_any_instance_of(ChatMessage).to receive(:should_generate_embedding?).and_call_original
    end

    describe "#should_generate_embedding?" do
      context "when content is present and no embedding exists" do
        it "returns true" do
          expect(message.send(:should_generate_embedding?)).to be true
        end
      end

      context "when content is blank" do
        before { message.content = "" }

        it "returns false" do
          expect(message.send(:should_generate_embedding?)).to be false
        end
      end

      context "when embedding already exists" do
        it "returns false" do
          # Create and save a message first
          saved_message = create(:chat_message)
          
          # Manually set an embedding using raw SQL to simulate existing embedding
          embedding_array = Array.new(3072, 0.2) # Create a test embedding  
          formatted_embedding = "[#{embedding_array.join(',')}]"
          ActiveRecord::Base.connection.execute(
            "UPDATE chat_messages SET content_embedding = '#{formatted_embedding}' WHERE id = #{saved_message.id}"
          )
          
          # Reload to get the updated embedding
          saved_message.reload
          
          # should_generate_embedding? should return false when embedding exists
          expect(saved_message.send(:should_generate_embedding?)).to be false
        end
      end
    end

    describe "#generate_embedding" do
      let(:saved_message) { create(:chat_message) }

      context "when message has content" do
        it "calls OllamaEmbeddingService" do
          embedding_service = instance_double(OllamaEmbeddingService)
          allow(OllamaEmbeddingService).to receive(:new).and_return(embedding_service)
          allow(embedding_service).to receive(:generate_embedding).and_return(Array.new(3072, 0.1))

          saved_message.generate_embedding

          expect(OllamaEmbeddingService).to have_received(:new).at_least(:once)
          expect(embedding_service).to have_received(:generate_embedding).with(saved_message.content).at_least(:once)
        end

        it "updates the content_embedding column" do
          embedding_service = instance_double(OllamaEmbeddingService)
          allow(OllamaEmbeddingService).to receive(:new).and_return(embedding_service)
          allow(embedding_service).to receive(:generate_embedding).and_return(Array.new(3072, 0.1))

          saved_message.generate_embedding
          saved_message.reload

          expect(saved_message.content_embedding).to be_present
        end
      end

      context "when message has no content" do
        before { saved_message.update_column(:content, "") }

        it "does not generate embedding" do
          expect(EmbeddingService).not_to receive(:new)
          saved_message.generate_embedding
        end
      end

      context "when message is not saved" do
        let(:unsaved_message) { build(:chat_message) }

        it "does not generate embedding" do
          expect(EmbeddingService).not_to receive(:new)
          unsaved_message.generate_embedding
        end
      end
    end

    describe "callbacks" do
      it "triggers embedding generation after save" do
        message = build(:chat_message)
        
        # Stub the actual embedding generation but allow the callback logic to work
        expect(message).to receive(:generate_embedding_sync_then_async)
        message.save!
      end
    end
  end

  describe ".find_similar_messages" do
    let!(:user) { create(:chat_user) }
    
    context "when query is blank" do
      it "returns empty array" do
        expect(ChatMessage.find_similar_messages("", user.id)).to eq([])
      end
    end

    context "when embedding service fails" do
      before do
        embedding_service = instance_double(EmbeddingService)
        allow(EmbeddingService).to receive(:new).and_return(embedding_service)
        allow(embedding_service).to receive(:generate_embedding).and_return(nil)
      end

      it "returns empty array" do
        expect(ChatMessage.find_similar_messages("test query", user.id)).to eq([])
      end
    end

    context "with valid embeddings", :skip_embedding_test do
    end
  end

  describe "#format_embedding_for_db" do
    let(:message) { create(:chat_message) }

    it "formats array as PostgreSQL array string" do
      embedding = [0.1, 0.2, 0.3]
      result = message.send(:format_embedding_for_db, embedding)
      expect(result).to eq('[0.1,0.2,0.3]')
    end

    it "returns nil for non-array input" do
      result = message.send(:format_embedding_for_db, "not an array")
      expect(result).to be_nil
    end
  end
end
