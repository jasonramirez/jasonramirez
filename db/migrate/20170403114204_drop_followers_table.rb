class DropFollowersTable < ActiveRecord::Migration[4.2]
  def change
    drop_table :followers
  end
end
