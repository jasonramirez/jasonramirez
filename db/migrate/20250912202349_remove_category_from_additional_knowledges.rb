class RemoveCategoryFromAdditionalKnowledges < ActiveRecord::Migration[8.0]
  def change
    remove_index :additional_knowledges, :category
    remove_column :additional_knowledges, :category, :string
  end
end
