class AddContentEmbeddingToKnowledgeItems < ActiveRecord::Migration[8.0]
  def change
    add_column :knowledge_items, :content_embedding, :text
  end
end
