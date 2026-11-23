# Scenarios tagged @javascript run in headless Chrome, so the Stimulus controllers really execute.
# Everything else stays on rack_test and needs no browser.
Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  %w[headless=new autoplay-policy=no-user-gesture-required mute-audio window-size=430,932].each do |argument|
    options.add_argument("--#{argument}")
  end
  Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
end

Capybara.javascript_driver = :headless_chrome
Capybara.default_max_wait_time = 5
