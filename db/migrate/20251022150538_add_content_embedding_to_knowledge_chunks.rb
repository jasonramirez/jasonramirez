class AddContentEmbeddingToKnowledgeChunks < ActiveRecord::Migration[8.0]
  def change
    add_column :knowledge_chunks, :content_embedding, :text unless column_exists?(:knowledge_chunks, :content_embedding)
  end
end
