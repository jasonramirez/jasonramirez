module PostsHelper
  def loom_params
    "?hide_owner=true&hide_title=true&hideEmbedTopBar=true"
  end

  def more_than_one_post
    Post.all.count > 1
  end

  def parsed_body
    MarkdownParser.new(@post.post_markdown).markdown_to_html
  end

  def video_src
    "#{@post.video_src} + #{loom_params}"
  end
end
