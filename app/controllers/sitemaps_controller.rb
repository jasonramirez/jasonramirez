class SitemapsController < ApplicationController
  def show
    @posts = Post.where(published: true).order(updated_at: :desc)
    
    respond_to do |format|
      format.xml { render layout: false }
    end
  end
end
