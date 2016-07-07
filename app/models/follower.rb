class Follower < ActiveRecord::Base
  validates :email, presence: true

  has_and_belongs_to_many :interests
end
