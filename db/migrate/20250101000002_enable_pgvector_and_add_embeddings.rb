  class EnablePgvectorAndAddEmbeddings < ActiveRecord::Migration[8.0]
    def change
      # Note: pgvector extension is enabled by superuser in setup script
      
      # Add embedding columns to knowledge_items (OpenAI text-embedding-3-small uses 1536 dimensions)
      add_column :knowledge_items, :content_embedding, :vector, limit: 1536
      add_column :knowledge_items, :title_embedding, :vector, limit: 1536
      
      # Add embedding columns for conversation memory
      add_column :chat_messages, :content_embedding, :vector, limit: 1536
      
      # Add indexes for vector similarity search (will be added after data is populated)
      # Note: HNSW indexes require data to be present, so we'll add these later
    end
  end
