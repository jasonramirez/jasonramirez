class CreateHashtags < ActiveRecord::Migration[7.0]
  def change
    create_table :hashtags do |t|
      t.string :label

      t.timestamps
    end

    create_table :hashtags_posts, id: false do |t|
      t.belongs_to :hashtag
      t.belongs_to :post
    end
  end
end
