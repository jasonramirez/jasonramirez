class AddContentEmbeddingToChatMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :chat_messages, :content_embedding, :text unless column_exists?(:chat_messages, :content_embedding)
  end
end
