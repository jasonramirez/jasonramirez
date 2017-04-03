class DropFollowersInterestsTable < ActiveRecord::Migration
  def change
    drop_table :followers_interests
  end
end
