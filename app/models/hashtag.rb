class Hashtag < ActiveRecord::Base
  has_and_belongs_to_many :posts

  validates :label, presence: true

  before_save do
    label_withouth_special_characters = remove_special_characters(self.label)

    self.label = add_hashtag(label_withouth_special_characters)
  end

  def remove_special_characters(string)
    string.downcase.gsub(special_characters, "")
  end

  def add_hashtag(string)
    string.insert(0, "#")
  end

  def special_characters
    /(\'|\"|\.|\*|\/|\-|\\|\+|\_|\ |\#)/
  end
end
