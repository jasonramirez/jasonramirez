Rails.application.routes.draw do
  devise_for :admins
  mount Lockup::Engine, at: "/lockup"

  root "welcome#index"

  resources :followers, only: [:new, :create]
  resources :posts, only: [:index, :show]

  get "admin", to: "admins/posts#index"
  get "case_studies", to: "case_studies#index"
  get "case_studies/:case_study", to: "case_studies#show"
  get "protected_case_studies/:protected_case_study",
    to: "protected_case_studies#show"
  get "privacy_and_terms", to: "privacy_and_terms#index"
  get "values_and_principles", to: "values_and_principles#index"

  namespace "admins" do
    resources :posts
  end
end
