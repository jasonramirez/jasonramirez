class PopulatePostTextForExistingPosts < ActiveRecord::Migration[8.0]
  def up
    # Create a temporary class to avoid model loading issues during migration
    post_table = Class.new(ActiveRecord::Base) do
      self.table_name = 'posts'
    end
    
    # Populate post_text for all existing posts that have post_markdown
    post_table.where.not(post_markdown: [nil, '']).find_each do |post|
      # Simple HTML tag removal for plain text
      if post.post_markdown.present?
        # Convert markdown to plain text by removing markdown syntax
        plain_text = post.post_markdown
                         .gsub(/\*\*(.*?)\*\*/, '\1')     # Bold **text**
                         .gsub(/\*(.*?)\*/, '\1')         # Italic *text*
                         .gsub(/`(.*?)`/, '\1')           # Code `text`
                         .gsub(/^[#]{1,6}\s+/, '')        # Headers # ## ###
                         .gsub(/^\s*[-*+]\s+/, '')        # List items
                         .gsub(/^\s*\d+\.\s+/, '')        # Numbered lists
                         .gsub(/\[([^\]]+)\]\([^)]+\)/, '\1') # Links [text](url)
                         .gsub(/\n+/, ' ')                # Multiple newlines to space
                         .gsub(/\s+/, ' ')                # Multiple spaces to single space
                         .strip
        
        post.update_column(:post_text, plain_text)
      end
    end
  end
  
  def down
    # Clear post_text field
    execute "UPDATE posts SET post_text = NULL"
  end
end