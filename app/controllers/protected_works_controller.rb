class ProtectedWorksController < ApplicationController
  before_action :check_for_lockup

  def show
    @protected_work = params[:protected_work]
  end
end
