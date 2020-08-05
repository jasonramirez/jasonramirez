class DropFollowersInterestsTable < ActiveRecord::Migration[4.2]
  def change
    drop_table :followers_interests
  end
end
