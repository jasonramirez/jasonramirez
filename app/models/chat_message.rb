class ChatMessage < ActiveRecord::Base
  belongs_to :chat_user
  
  validates :content, presence: true
  validates :message_type, presence: true, inclusion: { in: %w[question answer] }
  
  scope :for_user, ->(user_id) { where(chat_user_id: user_id) }
  scope :ordered, -> { order(created_at: :asc) }
end
