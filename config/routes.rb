Rails.application.routes.draw do
  root "welcome#index"

  get "case_studies", to: "case_studies#index"
  get "case_studies/:case_study", to: "case_studies#show"
  get "posts", to: "posts#index"
  get "posts/:post_title", to: "posts#show"
  get "process", to: "process#show"
end
