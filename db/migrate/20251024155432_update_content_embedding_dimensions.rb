class UpdateContentEmbeddingDimensions < ActiveRecord::Migration[8.0]
  def up
    # Clear existing embedding data to avoid dimension conflicts
    execute "UPDATE additional_knowledges SET content_embedding = NULL WHERE content_embedding IS NOT NULL"
    execute "UPDATE knowledge_items SET content_embedding = NULL WHERE content_embedding IS NOT NULL"
    execute "UPDATE chat_messages SET content_embedding = NULL WHERE content_embedding IS NOT NULL"
    execute "UPDATE knowledge_chunks SET content_embedding = NULL WHERE content_embedding IS NOT NULL"
    
    # Update additional_knowledges table
    change_column :additional_knowledges, :content_embedding, :vector, limit: 3072
    
    # Update knowledge_items table
    change_column :knowledge_items, :content_embedding, :vector, limit: 3072
    
    # Update chat_messages table
    change_column :chat_messages, :content_embedding, :vector, limit: 3072
    
    # Update knowledge_chunks table
    change_column :knowledge_chunks, :content_embedding, :vector, limit: 3072
  end

  def down
    # Revert to 1536 dimensions
    change_column :additional_knowledges, :content_embedding, :vector, limit: 1536
    change_column :knowledge_items, :content_embedding, :vector, limit: 1536
    change_column :chat_messages, :content_embedding, :vector, limit: 1536
    change_column :knowledge_chunks, :content_embedding, :vector, limit: 1536
  end
end
