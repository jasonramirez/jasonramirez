class CaseStudiesController < ApplicationController
  def index
  end

  def show
    @case_study = params[:case_study]
  end
end
