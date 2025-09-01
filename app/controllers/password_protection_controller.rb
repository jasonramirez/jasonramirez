class PasswordProtectionController < ApplicationController
  before_action :set_return_to

  def unlock
    if request.post?
      if params[:codeword] == ENV['LOCKUP_CODEWORD']
        session[:unlocked] = true
        redirect_to params[:return_to] || root_path
      else
        @wrong = true
        @return_to = params[:return_to]
        render :unlock
      end
    end
  end

  private

  def set_return_to
    @return_to = params[:return_to]
  end
end
