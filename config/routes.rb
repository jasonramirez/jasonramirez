Rails.application.routes.draw do
  devise_for :admins

  mount Lockup::Engine, at: "/lockup"

  root "welcome#index"

  resources :followers, only: [:new, :create]
  resources :posts, only: [:index, :show, :search]

  match "/403", to: "errors#prohibited", via: :all
  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all

  get "admin", to: "admins/posts#index"
  get "works", to: "works#index"
  get "works/:work", to: "works#show"
  get "protected_works/:protected_work", to: "protected_works#show"
  get "privacy_and_terms", to: "privacy_and_terms#index"
  get "principles", to: "principles#index"
  get "set_theme", to: "theme#update"
  get "values", to: "values#index"
  get "resume", to: "resume#show"

  namespace "admins" do
    resources :posts
    resources :hashtags
  end
end
