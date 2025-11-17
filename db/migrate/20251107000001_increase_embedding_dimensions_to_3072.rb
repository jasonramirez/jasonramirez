class IncreaseEmbeddingDimensionsTo3072 < ActiveRecord::Migration[8.0]
  def up
    # Drop indexes if they exist (created via rake tasks)
    execute "DROP INDEX IF EXISTS idx_knowledge_items_content_embedding"
    execute "DROP INDEX IF EXISTS idx_knowledge_items_title_embedding"
    execute "DROP INDEX IF EXISTS idx_knowledge_chunks_content_embedding"

    # Set all embeddings to NULL since we can't convert 1536-dim vectors to 3072-dim
    # They will need to be regenerated with the new dimension
    execute "UPDATE knowledge_items SET content_embedding = NULL, title_embedding = NULL"
    execute "UPDATE knowledge_chunks SET content_embedding = NULL"
    execute "UPDATE chat_messages SET content_embedding = NULL"
    execute "UPDATE additional_knowledges SET content_embedding = NULL"

    # Drop and recreate columns with new dimensions
    remove_column :knowledge_items, :content_embedding
    remove_column :knowledge_items, :title_embedding
    remove_column :knowledge_chunks, :content_embedding
    remove_column :chat_messages, :content_embedding
    remove_column :additional_knowledges, :content_embedding

    add_column :knowledge_items, :content_embedding, :vector, limit: 3072
    add_column :knowledge_items, :title_embedding, :vector, limit: 3072
    add_column :knowledge_chunks, :content_embedding, :vector, limit: 3072
    add_column :chat_messages, :content_embedding, :vector, limit: 3072
    add_column :additional_knowledges, :content_embedding, :vector, limit: 3072
  end

  def down
    # Drop indexes if they exist
    execute "DROP INDEX IF EXISTS idx_knowledge_items_content_embedding"
    execute "DROP INDEX IF EXISTS idx_knowledge_items_title_embedding"
    execute "DROP INDEX IF EXISTS idx_knowledge_chunks_content_embedding"

    # Set all embeddings to NULL
    execute "UPDATE knowledge_items SET content_embedding = NULL, title_embedding = NULL"
    execute "UPDATE knowledge_chunks SET content_embedding = NULL"
    execute "UPDATE chat_messages SET content_embedding = NULL"
    execute "UPDATE additional_knowledges SET content_embedding = NULL"

    # Drop and recreate columns with old dimensions
    remove_column :knowledge_items, :content_embedding
    remove_column :knowledge_items, :title_embedding
    remove_column :knowledge_chunks, :content_embedding
    remove_column :chat_messages, :content_embedding
    remove_column :additional_knowledges, :content_embedding

    add_column :knowledge_items, :content_embedding, :vector, limit: 1536
    add_column :knowledge_items, :title_embedding, :vector, limit: 1536
    add_column :knowledge_chunks, :content_embedding, :vector, limit: 1536
    add_column :chat_messages, :content_embedding, :vector, limit: 1536
    add_column :additional_knowledges, :content_embedding, :vector, limit: 1536
  end
end

