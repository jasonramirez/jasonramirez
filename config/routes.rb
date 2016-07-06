Rails.application.routes.draw do
  root "welcome#index"

  get "posts", to: "posts#index"
  get "posts/test", to: "posts#test"
  get "process", to: "process#show"
  get "works", to: "works#index"
  get "works/:work", to: "works#show"
end
