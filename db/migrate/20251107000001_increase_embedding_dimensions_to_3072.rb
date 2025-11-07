class IncreaseEmbeddingDimensionsTo3072 < ActiveRecord::Migration[8.0]
  def up
    change_column :knowledge_items, :content_embedding, :vector, limit: 3072
    change_column :knowledge_items, :title_embedding, :vector, limit: 3072
    change_column :knowledge_chunks, :content_embedding, :vector, limit: 3072
    change_column :chat_messages, :content_embedding, :vector, limit: 3072
    change_column :additional_knowledges, :content_embedding, :vector, limit: 3072
  end

  def down
    change_column :knowledge_items, :content_embedding, :vector, limit: 1536
    change_column :knowledge_items, :title_embedding, :vector, limit: 1536
    change_column :knowledge_chunks, :content_embedding, :vector, limit: 1536
    change_column :chat_messages, :content_embedding, :vector, limit: 1536
    change_column :additional_knowledges, :content_embedding, :vector, limit: 1536
  end
end

