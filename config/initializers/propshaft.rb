# Configure Propshaft to include JavaScript files for importmap
Rails.application.config.assets.paths << Rails.root.join("app", "javascript")
Rails.application.config.assets.paths << Rails.root.join("app", "javascript", "controllers")
