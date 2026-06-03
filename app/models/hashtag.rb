class Hashtag < ActiveRecord::Base
  has_and_belongs_to_many :posts

  validates :label, presence: true, uniqueness: { case_sensitive: false }

  before_save do
    if self.label.present?
      label_withouth_special_characters = remove_special_characters(self.label)
      self.label = add_hashtag(label_withouth_special_characters)
    end
  end

  def remove_special_characters(string)
    return "" if string.nil?
    string.downcase.gsub(special_characters, "").gsub(/\s+/, " ").strip
  end

  def add_hashtag(string)
    return "#" if string.blank?
    string.start_with?("#") ? string : "##{string}"
  end

  def special_characters
    /(\'|\"|\.|\*|\/|\-|\\|\+|\_|\#)/
  end

  def usage_count
    Post.joins(:hashtags).where(hashtags: [self.id]).pluck(:id).size
  end
end
