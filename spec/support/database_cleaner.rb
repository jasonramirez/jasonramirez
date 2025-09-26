RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(
      :truncation,
      except: %w(ar_internal_metadata)
    )
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :deletion
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  # Ensure clean state for feature tests
  config.before(:each, type: :feature) do
    # Clear any cached data that might interfere
    Rails.cache.clear if Rails.cache.respond_to?(:clear)
  end
end
