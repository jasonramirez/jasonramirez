module PostsHelper
  def video_src
    "#{@post.video_src} + #{loom_params}"
  end

  def parsed_body
    MarkdownParser.new(@post.body).markdown_to_html
  end

  def loom_params
    "?hide_owner=true&hide_title=true&hideEmbedTopBar=true"
  end

  def hashtag_with_comma(post_size, hashtag, index)
    unless index == post_size - 1
      "#{hashtag.label},"
    else
      hashtag.label
    end
  end
end
