# Configure Dart Sass to compile multiple entry points
Rails.application.config.dartsass.builds = {
  "application_dark.scss"  => "application_dark.css",
  "application_light.scss" => "application_light.css"
}

# Optional: readable CSS in development
Rails.application.config.dartsass.build_options = ["--style=expanded"]
