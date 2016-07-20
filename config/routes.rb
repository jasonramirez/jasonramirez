Rails.application.routes.draw do
  devise_for :admins

  root "welcome#index"

  resources :followers, only: [:new, :create]
  resources :posts, only: [:index, :show]

  get "case_studies", to: "case_studies#index"
  get "case_studies/:case_study", to: "case_studies#show"

  namespace "admins" do
    resources :posts
  end
end
