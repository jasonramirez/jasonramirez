ENV["RAILS_ENV"] = "test"

require File.expand_path("../../config/environment", __FILE__)
abort("DATABASE_URL environment variable is set") if ENV["DATABASE_URL"]

require "rspec/rails"
# require "selenium-webdriver"

Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |file| require file }

module Features
  # Extend this module in spec/support/features/*.rb
  include Formulaic::Dsl
end

RSpec.configure do |config|
  config.include Features, type: :feature
  config.infer_base_class_for_anonymous_controllers = false
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = false
  config.include Warden::Test::Helpers
  config.before :suite do
    Warden.test_mode!
  end
  
  # Set test environment variables
  config.before(:each) do
    ENV['LOCKUP_CODEWORD'] = 'test123'
    ENV['MAILCHIMP_API_KEY'] = 'test_key'
    ENV['MAILCHIMP_LIST_ID'] = 'test_list'
  end
end

# Configure Capybara to handle Turbo
Capybara.default_driver = :rack_test
Capybara.javascript_driver = :selenium_chrome_headless

# Register Chrome headless driver
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end
ActiveRecord::Migration.maintain_test_schema!
