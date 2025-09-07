class AddFeedbackTrackingToKnowledgeItems < ActiveRecord::Migration[8.0]
  def change
    add_column :knowledge_items, :feedback_score, :decimal, precision: 3, scale: 2, default: 0.5, null: false
    add_column :knowledge_items, :total_feedback_count, :integer, default: 0, null: false
    add_column :knowledge_items, :positive_feedback_count, :integer, default: 0, null: false
    add_column :knowledge_items, :last_feedback_at, :timestamp
    
    add_index :knowledge_items, :feedback_score
    add_index :knowledge_items, :last_feedback_at
  end
end
