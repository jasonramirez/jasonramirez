class Admins::ChatUsersController < ApplicationController
  before_action :authenticate_admin!
  layout "admin"
  def index
    @chat_users = ChatUser.includes(:chat_messages).order(created_at: :desc)
  end

  def new
    @chat_user = ChatUser.new
  end

  def create
    @chat_user = ChatUser.new(chat_user_params)
    
    if @chat_user.save
      redirect_to admins_chat_users_path, notice: "Chat user '#{@chat_user.name}' created successfully. They can now log in with their credentials."
    else
      render :new
    end
  end

  def show
    @chat_user = ChatUser.find(params[:id])
    @chat_messages = @chat_user.chat_messages.ordered
  end

  def edit
    @chat_user = ChatUser.find(params[:id])
  end

  def update
    @chat_user = ChatUser.find(params[:id])
    
    # Handle access_type if provided
    if params[:chat_user] && params[:chat_user][:access_type].present?
      case params[:chat_user][:access_type]
      when '48_hours'
        @chat_user.assign_attributes(chat_user_params.except(:access_type))
        @chat_user.login_expires_at = 48.hours.from_now
      when 'unlimited'
        @chat_user.assign_attributes(chat_user_params.except(:access_type))
        @chat_user.login_expires_at = nil
      end
    end
    
    if @chat_user.update(chat_user_params.except(:access_type))
      redirect_to edit_admins_chat_user_path(@chat_user), notice: "Jason AI user updated successfully."
    else
      render :edit
    end
  end
  
  def approve
    @chat_user = ChatUser.find(params[:id])
    @chat_user.approve!
    redirect_to admins_chat_users_path, notice: "Account approved for #{@chat_user.name}. Access will start when they first log in and expire 48 hours later."
  end
  

  private

  def chat_user_params
    params.require(:chat_user).permit(:name, :email, :password, :approved, :login_expires_at, :access_type)
  end
end
