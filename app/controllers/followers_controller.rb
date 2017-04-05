class FollowersController < ApplicationController
  def create
    subscription = MailchimpSubscriptionService.new(email: email).create()

    if subscription.errors?
      redirect_to new_follower_path, alert: subscription.error_message
    else
      redirect_to new_follower_path, notice: t("followers.new.success")
    end
  end

  private

  def email
    params[:follower][:email]
  end
end
