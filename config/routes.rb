Rails.application.routes.draw do
  root "welcome#index"

  resources :works, only: [:index]

  get "process", to: "process#show"

  [
    "penner",
    "piggy",
    "tinysplash",
  ].each do |work|
    get "works/#{work}", to: "works##{work}"
  end
end
