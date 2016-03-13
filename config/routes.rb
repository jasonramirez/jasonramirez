Rails.application.routes.draw do
  root "welcome#index"

  get "process", to: "process#show"

  [
    "frida_and_fred",
    "ouch",
    "penner",
    "piggy",
    "project_underdog",
    "repor",
    "tinysplash",
  ].each do |work|
    get "works/#{work}", to: "works##{work}"
  end
end
