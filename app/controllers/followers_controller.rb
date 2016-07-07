class FollowersController < ApplicationController
  def new
    @follower = Follower.new
  end

  def create
    @follower = Follower.new(follower_params)

    if @follower.save
      redirect_to posts_path, alert: "Success"
    else
      redirect_to new_follower_path, alert: "Failure"
    end
  end

  private

  def follower_params
    params.require(:follower).permit(:email, {interest_ids: []})
  end
end
