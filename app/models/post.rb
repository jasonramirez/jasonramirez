class Post < ActiveRecord::Base
  validates_presence_of :published

  def pretty_published_date
    published_date.strftime("%-m/%e/%y")
  end
end
