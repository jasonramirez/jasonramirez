class ImprovePostsForBetterSearch < ActiveRecord::Migration[8.0]
  def change
    # Rename the existing 'body' field to 'post_markdown' to be more explicit
    rename_column :posts, :body, :post_markdown
    
    # Add a new field for plain text content (for better search indexing)
    add_column :posts, :post_text, :text
  end
end