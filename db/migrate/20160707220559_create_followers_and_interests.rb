class CreateFollowersAndInterests < ActiveRecord::Migration
  def change
    create_table :followers_interests, id: false do |t|
      t.belongs_to :follower, index: true
      t.belongs_to :interest, index: true
    end
  end
end
