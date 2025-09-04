class Admins::HashtagsController < ApplicationController
  before_action :authenticate_admin!

  layout "admin"

  def index
    @hashtags = Hashtag.order(:label)
  end

  def new
    @hashtag = Hashtag.new
  end

  def create
    @hashtag = Hashtag.new(hashtag_params)

    if @hashtag.save
      redirect_to edit_admins_hashtag_path(@hashtag),
        notice: t("admins.flash.created")
    else
      redirect_to new_admins_hashtag_path,
        alert: t("admins.flash.failed")
    end
  end

  def edit
    @hashtag = find_hashtag
  end

  def update
    @hashtag = find_hashtag

    if @hashtag.update(hashtag_params)
      redirect_to edit_admins_hashtag_path(@hashtag),
        notice: t("admins.flash.updated")
    else
      redirect_to edit_admins_hashtag_path(@hashtag),
        alert: t("admins.flash.failed")
    end
  end

  def destroy
    hashtag = find_hashtag
    replacement_hashtag_id = params[:replacement_hashtag_id]

    # Require a replacement hashtag
    if replacement_hashtag_id.blank?
      redirect_to admins_hashtags_path,
        alert: "Please select a hashtag to replace with."
      return
    end

    # Replace the hashtag with another one
    replacement_hashtag = Hashtag.find(replacement_hashtag_id)
    replace_hashtag(hashtag, replacement_hashtag)

    if hashtag.destroy
      redirect_to admins_hashtags_path, 
        notice: "Hashtag replaced and deleted successfully."
    else
      redirect_to admins_hashtags_path,
        alert: t("admins.flash.failed")
    end
  end

  private

  def find_hashtag
    Hashtag.find(params[:id])
  end

  def hashtag_params
    params.require(:hashtag).permit(:label)
  end

  def replace_hashtag(old_hashtag, new_hashtag)
    # Find all posts that have the old hashtag
    posts_with_old_hashtag = Post.joins(:hashtags).where(hashtags: { id: old_hashtag.id })
    
    posts_with_old_hashtag.each do |post|
      # Remove the old hashtag and add the new one
      post.hashtags.delete(old_hashtag)
      post.hashtags << new_hashtag unless post.hashtags.include?(new_hashtag)
    end
  end
end
