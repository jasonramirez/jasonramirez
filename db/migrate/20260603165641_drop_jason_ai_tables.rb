class DropJasonAiTables < ActiveRecord::Migration[8.0]
  # Removes the jason.ai feature's tables. knowledge_chunks references
  # knowledge_items, so drop it first to satisfy the FK.
  def up
    drop_table :knowledge_chunks, if_exists: true
    drop_table :knowledge_items, if_exists: true
    drop_table :additional_knowledges, if_exists: true
    drop_table :chat_messages, if_exists: true
    drop_table :chat_users, if_exists: true
    drop_table :documents, if_exists: true

    # pgvector is no longer used now that embeddings are gone.
    execute "DROP EXTENSION IF EXISTS vector"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "jason.ai feature was removed"
  end
end
