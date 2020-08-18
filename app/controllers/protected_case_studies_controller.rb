class ProtectedCaseStudiesController < ApplicationController
  before_action :check_for_lockup

  def show
    @protected_case_study = params[:protected_case_study]
  end
end
