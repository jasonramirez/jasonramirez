ENV["RAILS_ENV"] = "test"

require File.expand_path("../../config/environment", __FILE__)
abort("DATABASE_URL environment variable is set") if ENV["DATABASE_URL"]

require "rspec/rails"
require "rails-controller-testing"

# Essential test helpers
begin
  require 'shoulda/matchers'
rescue LoadError
  # shoulda-matchers not available
end

begin
  require 'factory_bot_rails'
rescue LoadError
  # factory_bot_rails not available
end

Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |file| require file }

module Features
  # Extend this module in spec/support/features/*.rb
  include Formulaic::Dsl
end

RSpec.configure do |config|
  config.include Features, type: :feature
  config.include Devise::Test::ControllerHelpers, type: :controller
  # config.include Devise::Test::IntegrationHelpers, type: :request
  # config.include Rails::Controller::Testing::TestProcess, type: :controller
  # config.include Rails::Controller::Testing::TemplateAssertions, type: :controller
  # config.include Rails::Controller::Testing::Integration, type: :controller
  # config.infer_base_class_for_anonymous_controllers = false
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = true
  config.include Warden::Test::Helpers
  config.before :suite do
    Warden.test_mode!
  end
  
  # Include FactoryBot methods if available
  if defined?(FactoryBot)
    config.include FactoryBot::Syntax::Methods
  end
  
  # Minimal test setup
  config.before(:each) do
    # Reset FactoryBot sequences to prevent unique constraint violations
    FactoryBot.rewind_sequences
    
    # Skip ChatMessage embedding generation in tests to avoid transaction conflicts
    # Individual test files can override this behavior if needed
    allow_any_instance_of(ChatMessage).to receive(:should_generate_embedding?).and_return(false)
  end
end

# Configure shoulda-matchers if available
if defined?(Shoulda::Matchers)
  Shoulda::Matchers.configure do |config|
    config.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end
end

# # Configure Capybara to handle Turbo
# Capybara.default_driver = :rack_test
# Capybara.javascript_driver = :selenium_chrome_headless

# # Register Chrome headless driver
# Capybara.register_driver :selenium_chrome_headless do |app|
#   options = Selenium::WebDriver::Chrome::Options.new
#   options.add_argument('--headless')
#   options.add_argument('--no-sandbox')
#   options.add_argument('--disable-dev-shm-usage')
#   
#   Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
# end
ActiveRecord::Migration.maintain_test_schema!

# Mock OpenAI API calls in tests
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.before(:each) do
    # Stub OpenAI embeddings API to prevent real API calls during tests
    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return(
        status: 200,
        body: {
          data: [
            { embedding: Array.new(1536) { rand(-1.0..1.0) } }
          ]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end
