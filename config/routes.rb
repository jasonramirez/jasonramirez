Rails.application.routes.draw do
  devise_for :admins, controllers: { sessions: 'admins/sessions' }

  get "password_protection/unlock", to: "password_protection#unlock", as: :password_protection_unlock
  post "password_protection/unlock", to: "password_protection#unlock"

  root "welcome#index"

  resources :posts, only: [:index, :show] do
    collection do
      get :search
    end
  end

  match "/403", to: "errors#prohibited", via: :all
  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all

  get "admin", to: "admins/posts#index"
  get "feed.json", to: "posts#feed", format: :json
  get "philosophy", to: "philosophy#index"
  get "protected_works/:protected_work", to: "protected_works#show"
  get "privacy_and_terms", to: "privacy_and_terms#index"
  get "sitemap.xml", to: "sitemaps#show", format: :xml
  get "works", to: "works#index"

  namespace "admins" do
    resources :posts
    resources :hashtags
  end

  # Redirects for old URLs that may have been indexed or bookmarked
  get "principles", to: redirect("/philosophy")
  get "values", to: redirect("/philosophy")
end
