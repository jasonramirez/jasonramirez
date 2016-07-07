class Follower < ActiveRecord::Base
  validates :email, presence: true
end
