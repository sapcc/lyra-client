$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "lyra_client"

RSpec.configure do |config|
  config.mock_with :rspec
  config.order = "random"

  # Excon
  config.before(:all) do
    Excon.defaults[:mock] = true
  end
  config.after(:each) do
    Excon.stubs.clear
  end
end