class ChangePostLongTitleToSummary < ActiveRecord::Migration[7.0]
  def change
    rename_column :posts, :long_title, :summary
    change_column :posts, :summary, :text
  end
end
