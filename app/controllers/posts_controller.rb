class PostsController < ApplicationController
  def index
  end

  def show
    @post = MarkdownParser.new(post_markdown).markdown_to_html
  end

  private

  def post_markdown
    File.read(File.join("app", "views", "posts", "#{post_title}.md"))
  end

  def post_title
    params[:post_title]
  end
end
