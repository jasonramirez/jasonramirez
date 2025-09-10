Rails.application.routes.draw do
  devise_for :admins

  get "password_protection/unlock", to: "password_protection#unlock", as: :password_protection_unlock
  post "password_protection/unlock", to: "password_protection#unlock"

  root "welcome#index"

  resources :followers, only: [:new, :create]
  resources :posts, only: [:index, :show] do
    collection do
      get :search
    end
  end

  match "/403", to: "errors#prohibited", via: :all
  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all

  delete "chat/logout", to: "chat_auth#logout", as: :chat_logout

  get "admin", to: "admins/posts#index"
  get "chat/login", to: "chat_auth#login", as: :chat_login
  get "chat/register", to: "chat_auth#register", as: :chat_register
  get "feed.json", to: "posts#feed", format: :json
  get "jason_ai", to: "jason_ai#index"
  get "jason_ai/check_audio/:question_hash", to: "jason_ai#check_audio", as: :check_jason_ai_audio
  get "philosophy", to: "philosophy#index"
  get "protected_works/:protected_work", to: "protected_works#show"
  get "privacy_and_terms", to: "privacy_and_terms#index"
  get "sitemap.xml", to: "sitemaps#show", format: :xml
  get "works", to: "works#index"
  get "works/:work", to: "works#show"
  
  post "chat/login", to: "chat_auth#login"
  post "chat/register", to: "chat_auth#register"
  post "jason_ai/ask", to: "jason_ai#ask", as: :ask_jason_ai
  post "jason_ai/render_message", to: "jason_ai#render_message"
  post "jason_ai/feedback", to: "jason_ai#feedback", as: :jason_ai_feedback
  
  namespace "admins" do
    resources :posts
    resources :hashtags
    resources :chat_users do
      member do
        patch :approve
      end
    end
    resources :documents, only: [:index, :show], param: :document
  end

  # Redirects for old URLs that may have been indexed or bookmarked
  get "principles", to: redirect("/philosophy")
  get "values", to: redirect("/philosophy")
end
