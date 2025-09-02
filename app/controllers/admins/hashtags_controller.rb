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

    if hashtag.destroy
      redirect_to admins_hashtags_path,
        notice: t("admins.flash.destroyed")
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
end
