class JasonAiController < ApplicationController
  before_action :require_chat_auth
  layout 'jason_ai'
  
  def index
    @chat_messages = current_chat_user.chat_messages.ordered
  end

  def ask
    @question = params[:question]

    if @question.present?
      # Store the user's question
      question_message = current_chat_user.chat_messages.create!(
        content: @question,
        message_type: 'question'
      )
      
      begin
        @conversation_service = ConversationService.new
        result = @conversation_service.respond_to_question(@question)
        
        # Handle both old string format and new hash format
        if result.is_a?(Hash)
          @response = result[:text]
          @audio_path = result[:audio_path]
          @kb_influence = result[:knowledge_base_influence]
        else
          @response = result
          @audio_path = nil
          @kb_influence = nil
        end
        
        # Store the AI's response
        response_message = current_chat_user.chat_messages.create!(
          content: @response,
          message_type: 'answer',
          audio_path: @audio_path,
          metadata: {
            knowledge_base_influence: @kb_influence
          }
        )
        
      rescue => e
        Rails.logger.error "Error in MyMindController#ask: #{e.message}"
        @response = "I'm sorry, I encountered an error processing your question. Please try again."
        @audio_path = nil
        @kb_influence = nil
        
        # Store the error response
        response_message = current_chat_user.chat_messages.create!(
          content: @response,
          message_type: 'answer',
          metadata: {
            knowledge_base_influence: nil
          }
        )
      end
    else
      @response = "Please provide a question."
      @audio_path = nil
      question_message = nil
      response_message = nil
    end

    respond_to do |format|
      format.html { redirect_to my_mind_path }
      format.json { 
        if question_message && response_message
          render json: {
            question_message: {
              id: question_message.id,
              content: question_message.content,
              message_type: question_message.message_type,
              created_at: question_message.created_at
            },
            response_message: {
              id: response_message.id,
              content: response_message.content,
              message_type: response_message.message_type,
              created_at: response_message.created_at
            },
            knowledge_base_influence: @kb_influence
          }
        else
          render json: { error: @response }, status: :unprocessable_entity
        end
      }
    end
  end

  def check_audio
    question_hash = params[:question_hash]
    
    # Look for audio file with this hash
    audio_file = Rails.root.join('public', 'audios', 'generated', "#{question_hash}.mp3")
    
    if audio_file.exist?
      render json: { audio_path: "/audios/generated/#{question_hash}.mp3" }
    else
      render json: { audio_path: nil }
    end
  end

  def render_message
    message_params = params[:message].dup
    # Convert created_at string to DateTime if it exists
    if message_params['created_at'].present?
      message_params['created_at'] = DateTime.parse(message_params['created_at'])
    end
    
    # Ensure id is properly set
    message_params['id'] = message_params['id'] || "temp-#{Time.current.to_i}"
    
    @message = OpenStruct.new(message_params)
    @kb_influence = params[:kb_influence]
    render partial: 'chat_message', locals: { 
      message: @message, 
      kb_influence: @kb_influence 
    }
  end
  
  private
  
  def require_chat_auth
    unless current_chat_user
      redirect_to chat_login_path, alert: "Please log in to access the chat."
    end
  end
  
  def current_chat_user
    @current_chat_user ||= ChatUser.find_by(id: session[:chat_user_id]) if session[:chat_user_id]
  end
  
  helper_method :current_chat_user
end
