class Post < ActiveRecord::Base
  validates_presence_of :published
end
