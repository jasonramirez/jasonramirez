module HashtagsHelper
  def hashtag_comma(size, index)
    "," unless index == size - 1
  end
end
