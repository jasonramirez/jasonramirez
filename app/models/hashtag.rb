class Hashtag < ActiveRecord::Base
  has_and_belongs_to_many :posts

  validates :label, presence: true

  before_save do
    self.label = self.label.downcase.gsub(special_characters, "")
  end

  def special_characters
    /(\'|\"|\.|\*|\/|\-|\\|\+|\ )/
  end
end
