class PostsController < ApplicationController
  def index
  end

  def show
    @post_title = params[:post_title]
  end
end
