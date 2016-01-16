Rails.application.routes.draw do
  root "welcome#index"

  get "works/tinysplash", to: "works#tinysplash"
end
