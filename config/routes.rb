Rails.application.routes.draw do
  root "welcome#index"

  get "process", to: "process#show"
  get "works/piggy", to: "works#piggy"
  get "works/tinysplash", to: "works#tinysplash"
end
