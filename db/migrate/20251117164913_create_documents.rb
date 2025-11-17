class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents do |t|
      t.string :title
      t.string :slug
      t.text :content_markdown

      t.timestamps
    end

    add_index :documents, :slug, unique: true
  end
end
