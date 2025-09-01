class CreateMyMindFeature < ActiveRecord::Migration[7.1]
  def change
    # Create chat_users table
    create_table :chat_users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.boolean :approved, default: false
      t.datetime :login_expires_at
      
      t.timestamps
    end
    
    add_index :chat_users, :email, unique: true
    
    # Create chat_messages table
    create_table :chat_messages do |t|
      t.references :chat_user, null: false, foreign_key: true
      t.text :content, null: false
      t.string :message_type, null: false
      t.string :audio_path
      t.jsonb :metadata
      
      t.timestamps
    end
    
    add_index :chat_messages, [:chat_user_id, :created_at]
    
    # Create knowledge_items table
    create_table :knowledge_items do |t|
      t.string :title
      t.text :content
      t.string :category
      t.text :tags
      t.decimal :confidence_score
      t.string :source
      t.datetime :last_updated

      t.timestamps
    end
  end
end
