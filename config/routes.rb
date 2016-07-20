Rails.application.routes.draw do
  root "welcome#index"

  resources :followers, only: [:new, :create]
  resources :posts, only: [:index, :show]

  get "case_studies", to: "case_studies#index"
  get "case_studies/:case_study", to: "case_studies#show"

  namespace "admin" do
    resources :posts
  end
end
