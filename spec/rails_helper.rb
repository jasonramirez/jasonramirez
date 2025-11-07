ENV["RAILS_ENV"] = "test"

require File.expand_path("../../config/environment", __FILE__)
# Safety check: prevent running tests against production database
# Allow DATABASE_URL in CI environments (CircleCI, GitHub Actions, etc.)
if ENV["DATABASE_URL"] && !ENV["CI"] && !ENV["CIRCLECI"]
  abort("DATABASE_URL environment variable is set. This could be dangerous in local development.")
end

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
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = true
  config.include Warden::Test::Helpers
  
  config.before(:suite) do
    Warden.test_mode!
  end
  
  # Include FactoryBot methods if available
  if defined?(FactoryBot)
    config.include FactoryBot::Syntax::Methods
  end
  
  config.before(:each) do
    # Reset FactoryBot sequences to prevent unique constraint violations
    FactoryBot.rewind_sequences
    
    # Skip ChatMessage embedding generation in tests to avoid transaction conflicts
    begin
      allow_any_instance_of(ChatMessage).to receive(:should_generate_embedding?).and_return(false)
    rescue NameError, ActiveRecord::StatementInvalid
      # Ignore if ChatMessage model isn't loaded yet or database issues
    end
  end

  # Stub OpenAI embeddings API to prevent real API calls during tests
  config.before(:each, type: :feature) do
    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return(
        status: 200,
        body: {
          data: [
            { embedding: Array.new(EmbeddingService::EMBEDDING_DIMENSION) { rand(-1.0..1.0) } }
          ]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
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

# Mock OpenAI API calls in tests
WebMock.disable_net_connect!(allow_localhost: true)

# Skip automatic schema maintenance in CI to avoid database conflicts
unless ENV["CI"] || ENV["CIRCLECI"]
  begin
    ActiveRecord::Migration.maintain_test_schema!
  rescue ActiveRecord::PendingMigrationError => e
    puts "Running pending migrations for test database..."
    # Enable pgvector extension first (requires superuser)
    system("RAILS_ENV=test rails runner \"ActiveRecord::Base.connection.execute('CREATE EXTENSION IF NOT EXISTS vector;')\"")
    # Run migrations
    system("RAILS_ENV=test rails db:migrate")
    ActiveRecord::Migration.maintain_test_schema!
  end
end
