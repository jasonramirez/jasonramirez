if ENV.fetch("COVERAGE", false)
  require "simplecov"
  SimpleCov.start "rails"
end

require "webmock/rspec"

# http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
  end

  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"
  config.order = :random
  
  # Configure output format for quieter tests
  config.default_formatter = 'progress' unless ENV['RSPEC_FORMATTER']
  
  # Suppress verbose output unless explicitly requested
  unless ENV['RSPEC_VERBOSE']
    config.filter_gems_from_backtrace 'capybara', 'selenium-webdriver'
    config.backtrace_exclusion_patterns = [
      /\/lib\/ruby\/gems/,
      /\/gems\//,
      /\/vendor\/bundle/,
      /\/\.rvm\//,
      /\/\.rbenv\//
    ]
  end
end

WebMock.disable_net_connect!(allow_localhost: true)
