require 'capybara/rails'
require 'capybara/rspec'
require 'selenium-webdriver'

# Configure Capybara for headless testing
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1280,720')
  options.add_argument('--disable-extensions')
  options.add_argument('--disable-plugins')
  options.add_argument('--disable-images')
  options.add_argument('--disable-logging')
  options.add_argument('--log-level=3')
  options.add_argument('--silent')
  # options.add_argument('--disable-javascript') # Commented out to allow turbo-streams
  
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: options
  )
end

# Always use headless for tests (unless explicitly overridden)
Capybara.default_driver = :selenium_chrome_headless
Capybara.javascript_driver = :selenium_chrome_headless

# Configure Capybara
Capybara.default_max_wait_time = 10
Capybara.server = :puma, { Silent: true }
