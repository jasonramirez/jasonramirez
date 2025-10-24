source "https://rubygems.org"

ruby "3.2.9"

gem "autoprefixer-rails"
gem "bcrypt"
gem "browser"
gem "delayed_job_active_record"
gem "devise"
gem "flutie"
gem "friendly_id"
gem "gibbon"
gem "high_voltage"
gem "importmap-rails"
gem "rack-canonical-host"
gem "rack-rewrite"
gem "rails", "~> 8.0"
gem "recipient_interceptor"
gem "redcarpet"
gem "redis"
gem "rouge-rails"
# AI/LLM Services - Migrating to Ollama
# gem "ruby-openai"  # Commented out during Ollama migration
# gem "elevenlabs"   # Commented out during Ollama migration
gem "pgvector"
gem "neighbor"
gem "normalize-rails", "~> 3.0.0"
gem "pg"
gem "puma", ">= 7.0.3"
gem "gemoji"
gem "dartsass-rails"
gem "simple_form"
gem "slim"
gem "propshaft"
gem "stimulus-rails"
gem "turbo-rails"
gem "title"

group :development do
  gem "bundler-audit"
  gem "hotwire-livereload"
  gem "spring"
  gem "spring-commands-rspec"
  gem "web-console"
end

group :development, :test do
  gem "awesome_print"
  gem "bullet"
  gem "dotenv-rails"
  gem "factory_bot_rails"
  gem "pry-byebug"
  gem "pry-rails"
  gem "rspec-rails"
end

group :test do
  gem "database_cleaner"
  gem "formulaic"
  gem "launchy"
  gem "rails-controller-testing"
  gem "rspec_junit_formatter"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
  gem "simplecov", require: false
  gem "timecop"
  gem "webmock"
end

group :staging, :production do
  gem "rack-timeout"
end

