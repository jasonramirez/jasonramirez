# Pin npm packages by running ./bin/importmap

# Main entrypoint
pin "application", preload: true

# Hotwired dependencies (canonical importmap pins)
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# Libraries
pin "hammerjs", to: "https://ga.jspm.io/npm:hammerjs@2.0.8/hammer.js"

# Controller dependencies
pin_all_from "app/javascript/controllers", under: "controllers" 

# Custom dependencies
pin "admin-table-scroll", to: "admin-table-scroll.js"
pin "carousel", to: "carousel.js"
pin "custom-audio-player", to: "custom-audio-player.js"
pin "drawer", to: "drawer.js"
pin "flexible-textarea", to: "flexible-textarea.js"
pin "modal", to: "modal.js"
pin "my-mind", to: "my-mind.js"
pin "reading-progress-bar", to: "reading-progress-bar.js"
pin "sky-labels", to: "sky-labels.js"
