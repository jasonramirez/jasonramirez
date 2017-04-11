class Post < ActiveRecord::Base
  validates :title, presence: true

  extend FriendlyId
  friendly_id :title, use: :slugged

  def display_title
    unless long_title.blank?
      return long_title
    end

    title
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

  def should_generate_new_friendly_id?
    title_changed?
  end
end
