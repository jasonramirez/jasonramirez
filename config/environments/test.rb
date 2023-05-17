Rails.application.configure do
  config.action_controller.allow_forgery_protection = false
  config.action_controller.perform_caching = false
  config.action_dispatch.show_exceptions = false
  config.action_mailer.default_url_options = { host: "www.example.com" }
  config.action_mailer.delivery_method = :test
  config.active_job.queue_adapter = :inline
  config.active_record.legacy_connection_handling = false
  config.active_support.deprecation = :stderr
  config.active_support.test_order = :random
  config.assets.raise_runtime_errors = true
  config.assets.unknown_asset_fallback = true
  config.cache_classes = false
  config.consider_all_requests_local = true
  config.eager_load = false
  config.log_level = :warn
  config.serve_static_files = true
  config.static_cache_control = 'public, max-age=3600'
end
