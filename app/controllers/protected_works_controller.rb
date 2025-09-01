class ProtectedWorksController < ApplicationController
  include PasswordProtectable

  def show
    @protected_work = params[:protected_work]
  end
end
