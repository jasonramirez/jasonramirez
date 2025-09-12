class RemovePriorityFromAdditionalKnowledges < ActiveRecord::Migration[8.0]
  def change
    remove_index :additional_knowledges, :priority
    remove_column :additional_knowledges, :priority, :integer
  end
end
