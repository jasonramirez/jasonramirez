require 'rails_helper'

RSpec.describe "ChatMessage Conversation Memory", type: :model do
  let!(:user) { create(:chat_user) }

  describe "conversation memory bug fix" do
    it "retrieves the most recent messages in correct order" do
      # This test specifically validates the bug we fixed
      
      # Create messages with specific timestamps (simulating a real conversation)
      old_question = create(:chat_message, 
        chat_user: user, 
        content: "How do you build teams?", 
        message_type: "question",
        created_at: 2.hours.ago
      )
      
      old_answer = create(:chat_message, 
        chat_user: user, 
        content: "Building teams requires...", 
        message_type: "answer",
        created_at: 2.hours.ago + 1.minute
      )
      
      # More recent conversation about design systems
      design_question = create(:chat_message, 
        chat_user: user, 
        content: "How do you think about design systems?", 
        message_type: "question",
        created_at: 30.minutes.ago
      )
      
      design_answer = create(:chat_message, 
        chat_user: user, 
        content: "Design systems are essential for creating consistency...", 
        message_type: "answer",
        created_at: 25.minutes.ago
      )
      
      # Test that .recent returns newest messages first
      recent_messages = ChatMessage.for_user(user.id).recent(4)
      
      # Should be in reverse chronological order (newest first)
      expect(recent_messages).to eq([design_answer, design_question, old_answer, old_question])
      
      # Verify timestamps are descending
      timestamps = recent_messages.map(&:created_at)
      expect(timestamps).to eq(timestamps.sort.reverse)
    end

    it "provides correct context for follow-up questions" do
      # Create a conversation about design systems
      create(:chat_message, 
        chat_user: user, 
        content: "How do you think about design systems?", 
        message_type: "question",
        created_at: 10.minutes.ago
      )
      
      create(:chat_message, 
        chat_user: user, 
        content: "Design systems are essential for creating consistency and alignment across a product's user experience.", 
        message_type: "answer",
        created_at: 5.minutes.ago
      )
      
      # When asking "Say more", should get design systems context
      recent_messages = ChatMessage.for_user(user.id).recent(5)
      
      # The most recent messages should be about design systems
      content_text = recent_messages.first(2).map(&:content).join(" ")
      expect(content_text).to include("design systems")
      expect(content_text).to include("consistency")
    end

    it "conversation context building uses newest messages first" do
      # Create conversation in chronological order
      msg1 = create(:chat_message, chat_user: user, content: "First message", created_at: 3.hours.ago)
      msg2 = create(:chat_message, chat_user: user, content: "Second message", created_at: 2.hours.ago)  
      msg3 = create(:chat_message, chat_user: user, content: "Third message", created_at: 1.hour.ago)
      
      recent = ChatMessage.for_user(user.id).recent(3)
      
      # When we take first(2) of recent messages, should get the 2 newest
      newest_two = recent.first(2)
      expect(newest_two).to eq([msg3, msg2])
      expect(newest_two).not_to include(msg1)
    end
  end

  describe "conversation context detection" do
    it "detects when there is conversation history" do
      # No messages initially
      expect(ChatMessage.for_user(user.id).recent(5)).to be_empty
      
      # Create a message
      create(:chat_message, chat_user: user, content: "Hello")
      
      # Should now detect conversation history
      expect(ChatMessage.for_user(user.id).recent(5).count).to eq(1)
    end

    it "filters messages by user correctly" do
      other_user = create(:chat_user, email: "other@example.com")
      
      # Create messages for different users
      user_message = create(:chat_message, chat_user: user, content: "User message")
      other_message = create(:chat_message, chat_user: other_user, content: "Other user message")
      
      # Should only return messages for the specific user
      user_messages = ChatMessage.for_user(user.id).recent(10)
      expect(user_messages).to include(user_message)
      expect(user_messages).not_to include(other_message)
    end
  end
end
