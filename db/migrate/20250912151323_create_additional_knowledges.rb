class CreateAdditionalKnowledges < ActiveRecord::Migration[8.0]
  def change
    create_table :additional_knowledges do |t|
      t.string :title
      t.text :content
      t.string :category
      t.integer :priority, default: 0
      t.column :content_embedding, :vector, limit: 1536

      t.timestamps
    end

    add_index :additional_knowledges, :category
    add_index :additional_knowledges, :priority
  end
end
