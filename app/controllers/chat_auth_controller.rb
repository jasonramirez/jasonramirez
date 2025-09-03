class ChatAuthController < ApplicationController
  def login
    flash.clear if request.get?
    
    if request.post?
      user = ChatUser.authenticate(params[:email], params[:password])
      
      if user
        session[:chat_user_id] = user.id
        session[:chat_user_name] = user.name
        redirect_to my_mind_path, notice: "Welcome back, #{user.name}!"
      else
        flash.now[:alert] = "Invalid email or password, your account hasn't been approved, or your login has expired."
        render :login
      end
    end
  end
  
  def logout
    session[:chat_user_id] = nil
    session[:chat_user_name] = nil
    redirect_to chat_login_path, notice: "You have been logged out."
  end
  
  def register
    if request.post?
      @user = ChatUser.new(user_params)
      
      if @user.save
        redirect_to chat_login_path, notice: "Account request submitted successfully! You'll receive an email when your account is approved. All accounts are given 48 hours of access from the moment of approval."
      else
        render :register
      end
    else
      @user = ChatUser.new
    end
  end
  
  private
  
  def user_params
    params.require(:chat_user).permit(:name, :email, :password)
  end
end
