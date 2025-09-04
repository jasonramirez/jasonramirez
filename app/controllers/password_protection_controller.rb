class PasswordProtectionController < ApplicationController
  before_action :set_return_to

  def unlock
    if request.post?
      codeword = params[:password_protection][:codeword]
      return_to = params[:password_protection][:return_to]
      
      if codeword == ENV['LOCKUP_CODEWORD']
        session[:unlocked] = true
        redirect_to return_to || root_path
      else
        @wrong = true
        @return_to = return_to
        render :unlock
      end
    end
  end

  private

  def set_return_to
    @return_to = params[:return_to]
  end
end
