class ChangeFeedbackCountsToDecimal < ActiveRecord::Migration[8.0]
  def change
    change_column :knowledge_items, :total_feedback_count, :decimal, precision: 8, scale: 2, default: 0.0, null: false
    change_column :knowledge_items, :positive_feedback_count, :decimal, precision: 8, scale: 2, default: 0.0, null: false
  end
end
