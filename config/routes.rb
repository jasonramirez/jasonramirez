Rails.application.routes.draw do
  root "welcome#index"

  get "works/piggy", to: "works#piggy"
  get "works/tinysplash", to: "works#tinysplash"
end
