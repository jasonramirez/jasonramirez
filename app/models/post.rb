class Post < ActiveRecord::Base
  validates :title, presence: true

  def display_title
    long_title || title
  end

  def pretty_published_date
    published_date.strftime("%-m/%-d/%y")
  end

  def published_state_class
    published || "not-published"
  end

  def published_state
    published ? "Published" : "Not Published"
  end
end
