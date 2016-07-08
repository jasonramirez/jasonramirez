Rails.application.routes.draw do
  root "welcome#index"

  resources :followers, only: [:new, :create]

  get "case_studies", to: "case_studies#index"
  get "case_studies/:case_study", to: "case_studies#show"
  get "posts", to: "posts#index"
  get "posts/:post_title", to: "posts#show"
end
