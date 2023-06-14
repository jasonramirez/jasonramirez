RailsLiveReload.configure do |config|
  config.url = "/rails/live/reload"

  config.watch %r{app/views/.+\.(erb|haml|slim)$}
  config.watch %r{(app|vendor)/(assets|javascript)/\w+/(.+\.(scss|css|js|html|png|jpg|ts|jsx)).*}, reload: :always
  config.watch %r{app/helpers/.+\.rb}, reload: :always
  config.watch %r{config/locales/.+\.yml}, reload: :always

  config.enabled = Rails.env.development?
end if defined?(RailsLiveReload)
