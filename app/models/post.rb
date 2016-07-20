class Post < ActiveRecord::Base
  validates :title, presence: true

  def pretty_published_date
    published_date.strftime("%-m/%e/%y")
  end
end
