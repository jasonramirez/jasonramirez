class AddContentEmbeddingToAdditionalKnowledges < ActiveRecord::Migration[8.0]
  def change
    add_column :additional_knowledges, :content_embedding, :text
  end
end
