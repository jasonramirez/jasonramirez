# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "jquery", to: "jquery.min.js", preload: true
pin "jquery_ujs", to: "jquery_ujs.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"

pin "carousel", to: "carousel.js"
pin "flexible-textarea", to: "flexible_textarea.js"
pin "hammerjs", to: "https://ga.jspm.io/npm:hammerjs@2.0.8/hammer.js"
pin "reading-progress-bar", to: "reading-progress-bar.js"
pin "sky-labels", to: "sky_labels.js"
