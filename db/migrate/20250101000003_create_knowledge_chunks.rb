class CreateKnowledgeChunks < ActiveRecord::Migration[8.0]
  def up
    create_table :knowledge_chunks do |t|
      t.references :knowledge_item, null: false, foreign_key: true
      t.text :content
      t.integer :chunk_index
      t.string :chunk_type
      t.string :title
      t.string :category
      t.text :tags
      t.decimal :confidence_score
      t.string :source
      t.datetime :last_updated
      t.column :content_embedding, :vector, limit: 1536

      t.timestamps
    end
    
    add_index :knowledge_chunks, :category
    add_index :knowledge_chunks, :chunk_type
  end

  def down
    drop_table :knowledge_chunks if table_exists?(:knowledge_chunks)
  end
end
