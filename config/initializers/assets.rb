# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile += %w(
  controllers/index.js
  controllers/share_controller.js 
  application_dark.css
  application_light.css
  carousel.js
  flexible_textarea.js
  jquery.min.js
  jquery_ujs.js
  reading-progress-bar.js
  sky_labels.js
)
