class ChangePostLongTitleToSummary < ActiveRecord::Migration[7.0]
  def change
    rename_column :posts, :long_title, :summary
  end
end
