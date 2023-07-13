class AddLongTitleToPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :long_title, :string
  end
end
