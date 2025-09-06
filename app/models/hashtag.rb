class Hashtag < ActiveRecord::Base
  has_and_belongs_to_many :posts

  validates :label, presence: true, uniqueness: { case_sensitive: false }

  scope :ordered_by_label, -> { order(:label) }

  before_save do
    if self.label.present?
      label_withouth_special_characters = remove_special_characters(self.label)
      self.label = add_hashtag(label_withouth_special_characters)
    end
  end

  def self.search_by_label(query)
    return none if query.blank?
    where("label ILIKE ?", "%#{query}%")
  end

  def remove_special_characters(string)
    return "" if string.nil?
    string.downcase.gsub(special_characters, "")
  end

  def add_hashtag(string)
    return "#" if string.blank?
    string.start_with?("#") ? string : "##{string}"
  end

  def special_characters
    /(\'|\"|\.|\*|\/|\-|\\|\+|\_|\#)/
  end

  def slug
    # Remove # and convert to slug
    clean_label = label.gsub(/^#/, '')
    clean_label.gsub(/[^a-zA-Z0-9\s]/, '').strip.gsub(/\s+/, '-').downcase
  end

  def display_name
    # Remove # and convert to title case, preserving word boundaries
    clean_label = label.gsub(/^#/, '')
    # Add spaces before capital letters that follow lowercase letters
    result = clean_label.gsub(/([a-z])([A-Z])/, '\1 \2')
    # Split into words and capitalize first letter of each, keeping small words lowercase
    words = result.split(/\s+/)
    words.map.with_index do |word, index|
      if index == 0 || !%w[a an and at but by for in of on or the to].include?(word.downcase)
        word.capitalize
      else
        word.downcase
      end
    end.join(' ')
  end

  def usage_count
    Post.joins(:hashtags).where(hashtags: [self.id]).pluck(:id).size
  end
end
