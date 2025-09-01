# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "jquery", to: "https://ga.jspm.io/npm:jquery@3.7.1/dist/jquery.js", preload: true
pin "jquery_ujs", to: "https://ga.jspm.io/npm:jquery_ujs@1.2.2/src/rails.js", preload: true
pin "@hotwired/stimulus", to: "https://ga.jspm.io/npm:@hotwired/stimulus@3.2.2/dist/stimulus.js", preload: true
pin "@hotwired/stimulus-loading", to: "https://ga.jspm.io/npm:@hotwired/stimulus-loading@2.0.0/dist/stimulus-loading.js", preload: true
pin "@hotwired/turbo", to: "https://ga.jspm.io/npm:@hotwired/turbo@7.3.0/dist/turbo.es2017-umd.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"

pin "carousel", to: "carousel.js"
pin "custom-audio-player", to: "custom-audio-player.js"
pin "drawer", to: "drawer.js"
pin "flexible-textarea", to: "flexible_textarea.js"
pin "admin-table-scroll", to: "admin-table-scroll.js"
pin "hammerjs", to: "https://ga.jspm.io/npm:hammerjs@2.0.8/hammer.js"
pin "modal", to: "modal.js"
pin "my-mind", to: "my-mind.js"
pin "reading-progress-bar", to: "reading-progress-bar.js"
pin "sky-labels", to: "sky_labels.js"
