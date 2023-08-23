class WorksController < ApplicationController
  def index
  end

  def show
    @works = params[:work]
  end
end
