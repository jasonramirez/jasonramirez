class WorksController < ApplicationController
  def index
  end

  def show
    @work = params[:work]
  end
end
