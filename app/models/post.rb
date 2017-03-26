class Post < ActiveRecord::Base
  validates :title, presence: true

  def display_title
    long_title || title
  end

  def pretty_published_date
    published_date.strftime("%-m/%-d/%y")
  end
end
