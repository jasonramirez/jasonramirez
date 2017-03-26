class AddLongTitleToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :long_title, :string
  end
end
