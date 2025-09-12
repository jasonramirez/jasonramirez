class CreateAdditionalKnowledges < ActiveRecord::Migration[8.0]
  def change
    create_table :additional_knowledges do |t|
      t.string :title
      t.text :content
      t.column :content_embedding, :vector, limit: 1536

      t.timestamps
    end
  end
end
