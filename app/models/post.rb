class Post < ActiveRecord::Base
  has_and_belongs_to_many :hashtags

  validates :title, presence: true

  extend FriendlyId
  friendly_id :title, use: :slugged

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
